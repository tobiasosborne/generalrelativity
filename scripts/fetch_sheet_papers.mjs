#!/usr/bin/env node
// Fetch exercise-sheet ground-truth papers via headed Playwright browser
// (TIB network required).
//
// Papers are declared in literature/<topic>/manifest.json so that we can
// accumulate ground-truth references sheet by sheet without editing this
// script.  Pass --manifest to override.
//
// Usage:
//   node scripts/fetch_sheet_papers.mjs
//   node scripts/fetch_sheet_papers.mjs --manifest literature/mercury-sun-quadrupole/manifest.json
//
// Prerequisites:
//   1. TIB network access (VPN or on-campus).
//   2. Playwright installed in the sibling FQHE project.
//
// Publisher challenge logic is inherited from scripts/fetch_equiv_papers.mjs
// and extended to cover Oxford Academic (OUP), needed for MNRAS.

import { chromium } from '/home/tobias/Projects/FQHE/node_modules/playwright/index.mjs';
import { writeFileSync, existsSync, mkdirSync, readFileSync } from 'fs';
import { resolve, dirname } from 'path';

const argv = process.argv.slice(2);
let manifestPath = null;
for (let i = 0; i < argv.length; i++) {
  if (argv[i] === '--manifest') manifestPath = argv[i + 1];
}
if (!manifestPath) {
  // Default: every manifest.json under literature/
  console.error('No --manifest given; expecting one.');
  process.exit(1);
}

const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
const PAPERS_DIR = resolve(manifestPath, '..');

// ───────────────────────────────────────────────────────────────
// Publisher-specific page-ready checks
// ───────────────────────────────────────────────────────────────
async function waitForPublisherPage(page, publisher, timeoutMs = 180000) {
  console.log(`Waiting for ${publisher} page (solve any challenges in the browser)...`);
  console.log(`>>> You have ${timeoutMs / 1000}s <<<\n`);

  const checks = {
    APS: () =>
      document.querySelector('meta[name="citation_title"]') ||
      document.querySelector('h3.title') ||
      document.querySelector('#article') ||
      (document.title && document.title.includes('Phys. Rev.')),
    IOP: () =>
      document.querySelector('meta[name="citation_title"]') ||
      document.querySelector('.article-content') ||
      (document.title && /Class\. Quantum Grav\.|Astrophys|Astron/.test(document.title)),
    Elsevier: () =>
      document.querySelector('meta[name="citation_title"]') ||
      document.querySelector('.article-header') ||
      document.querySelector('#abstracts') ||
      (document.title && document.title.includes('ScienceDirect')),
    Wiley: () =>
      document.querySelector('meta[name="citation_title"]') ||
      document.querySelector('.article-citation') ||
      document.querySelector('.article__header') ||
      (document.title && document.title.includes('Wiley')),
    OUP: () =>
      document.querySelector('meta[name="citation_title"]') ||
      document.querySelector('.article-title-main') ||
      document.querySelector('.content-navigation') ||
      (document.title && /Oxford Academic|Mon\. Not\.|MNRAS/.test(document.title)),
  };
  const check = checks[publisher] || checks.APS;
  try {
    await page.waitForFunction(check, { timeout: timeoutMs });
    const title = await page.title();
    console.log(`Page loaded: "${title}"\nAccess confirmed!\n`);
    await new Promise(r => setTimeout(r, 2000));
    return true;
  } catch (_) {
    return false;
  }
}

// ───────────────────────────────────────────────────────────────
// Main
// ───────────────────────────────────────────────────────────────
async function main() {
  mkdirSync(PAPERS_DIR, { recursive: true });

  const todo = manifest.papers.filter(p => !existsSync(resolve(PAPERS_DIR, p.file)));
  if (todo.length === 0) {
    console.log('All papers already downloaded. Nothing to do.');
    return;
  }
  console.log(`${todo.length}/${manifest.papers.length} papers to download.\n`);
  console.log('Launching HEADED Chromium (persistent profile)...');
  console.log('Make sure TIB network access is active!\n');

  const userDataDir = resolve(PAPERS_DIR, '..', '.browser-profile');
  mkdirSync(userDataDir, { recursive: true });

  const context = await chromium.launchPersistentContext(userDataDir, {
    headless: false,
    args: ['--disable-blink-features=AutomationControlled'],
    viewport: { width: 1280, height: 900 },
  });
  const page = context.pages()[0] || await context.newPage();

  let downloaded = 0, failed = 0, skipped = 0;

  // Group by publisher so challenges only happen once
  const byPublisher = {};
  for (const p of manifest.papers) (byPublisher[p.publisher] ||= []).push(p);

  for (const [publisher, papers] of Object.entries(byPublisher)) {
    const firstTodo = papers.find(p => !existsSync(resolve(PAPERS_DIR, p.file)));
    if (!firstTodo) {
      for (const p of papers) { console.log(`SKIP ${p.id}`); skipped++; }
      continue;
    }

    console.log(`--- ${publisher} ---`);
    console.log(`Navigating to: ${firstTodo.triggerUrl}`);
    await page.goto(firstTodo.triggerUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
    const passed = await waitForPublisherPage(page, publisher);
    if (!passed) console.log(`WARNING: ${publisher} not confirmed; trying anyway.\n`);

    for (const paper of papers) {
      const outPath = resolve(PAPERS_DIR, paper.file);
      if (existsSync(outPath)) { console.log(`SKIP ${paper.id}`); skipped++; continue; }

      try {
        process.stdout.write(`FETCH ${paper.id}: ${paper.file} ... `);
        let body = null;

        // Attempt 1: direct API request (session cookies carried by context)
        const response = await page.request.get(paper.url, { timeout: 30000 });
        if (response.status() === 200) body = await response.body();

        // Attempt 2: navigate via browser
        if (!body || body.slice(0, 5).toString() !== '%PDF-') {
          await page.goto(paper.triggerUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
          await new Promise(r => setTimeout(r, 2000));
          const pdfResponse = await page.goto(paper.url, { waitUntil: 'commit', timeout: 30000 }).catch(() => null);
          if (pdfResponse && pdfResponse.status() === 200) body = await pdfResponse.body();
        }

        // Attempt 3: publisher-specific fallback (Elsevier/Wiley/OUP)
        if (!body || body.slice(0, 5).toString() !== '%PDF-') {
          if (publisher === 'OUP') {
            // OUP: article page loads fine, but PDF endpoint is guarded.
            // Tactic: navigate to article, locate PDF link, then fetch
            // via page.evaluate so the request is same-origin with full
            // cookies (bot-detection is more permissive on fetch from page).
            await page.goto(paper.triggerUrl, { waitUntil: 'load', timeout: 30000 });
            await new Promise(r => setTimeout(r, 3000));
            const pdfHref = await page.locator(
              'a.article-pdfLink, a[href*="article-pdf"], a[href$=".pdf"], a[data-track-label="PDF"]'
            ).first().getAttribute('href').catch(() => null);
            if (pdfHref) {
              const pdfUrl = pdfHref.startsWith('http') ? pdfHref : `https://academic.oup.com${pdfHref}`;
              // Listen for PDF response while navigating the tab
              const pdfPromise = new Promise((resolveP) => {
                const timeout = setTimeout(() => resolveP(null), 25000);
                const handler = async (resp) => {
                  try {
                    const ct = (resp.headers()['content-type'] || '').toLowerCase();
                    if (ct.includes('pdf')) {
                      const b = await resp.body();
                      if (b.slice(0, 5).toString() === '%PDF-') {
                        clearTimeout(timeout);
                        page.removeListener('response', handler);
                        resolveP(b);
                      }
                    }
                  } catch (_) {}
                };
                page.on('response', handler);
              });
              await page.goto(pdfUrl, { waitUntil: 'commit', timeout: 30000 }).catch(() => null);
              body = await pdfPromise;
            }
          } else if (publisher === 'Wiley') {
            await page.goto(paper.triggerUrl, { waitUntil: 'load', timeout: 30000 });
            await new Promise(r => setTimeout(r, 3000));
            for (const sel of ['.coolBar--download a[href*="pdf"]', 'a[href*="epdf"]', 'a[href*="pdfdirect"]']) {
              try {
                const el = page.locator(sel).first();
                if (await el.count() === 0) continue;
                const [download] = await Promise.all([
                  page.waitForEvent('download', { timeout: 15000 }).catch(() => null),
                  el.click({ timeout: 5000 }),
                ]);
                if (download) {
                  const tmp = await download.path();
                  if (tmp) { body = readFileSync(tmp); break; }
                }
              } catch (_) { continue; }
            }
          } else if (publisher === 'Elsevier') {
            await page.goto(paper.triggerUrl, { waitUntil: 'load', timeout: 30000 });
            await new Promise(r => setTimeout(r, 3000));
            const pdfHref = await page.locator('a[href*="/pdf"]').first().getAttribute('href').catch(() => null);
            if (pdfHref) {
              const pdfUrl = pdfHref.startsWith('http') ? pdfHref : `https://www.sciencedirect.com${pdfHref}`;
              const pdfPromise = new Promise((resolveP) => {
                const timeout = setTimeout(() => resolveP(null), 25000);
                const handler = async (resp) => {
                  try {
                    const b = await resp.body();
                    if (b.length > 1000 && b.slice(0, 5).toString() === '%PDF-') {
                      clearTimeout(timeout);
                      page.removeListener('response', handler);
                      resolveP(b);
                    }
                  } catch (_) {}
                };
                page.on('response', handler);
              });
              await page.goto(pdfUrl, { waitUntil: 'load', timeout: 30000 }).catch(() => null);
              await new Promise(r => setTimeout(r, 5000));
              body = await pdfPromise;
            }
          }
        }

        if (!body) { console.log('FAIL (no PDF obtained)'); failed++; continue; }
        if (body.slice(0, 5).toString() !== '%PDF-') {
          console.log(`FAIL (not a PDF: "${body.slice(0, 16).toString()}")`);
          failed++; continue;
        }

        writeFileSync(outPath, body);
        console.log(`OK (${(body.length / 1024).toFixed(0)} KB)`);
        downloaded++;
        await new Promise(r => setTimeout(r, 1500));
      } catch (e) {
        console.log(`ERROR: ${e.message}`);
        failed++;
      }
    }
    console.log('');
  }

  console.log(`Done: ${downloaded} downloaded, ${failed} failed, ${skipped} skipped`);
  await context.close();
}

main().catch(e => { console.error(e); process.exit(1); });
