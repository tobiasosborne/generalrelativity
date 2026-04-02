#!/usr/bin/env node
// Fetch equivalence-principle papers via headed Playwright browser (TIB network required).
// Usage: node scripts/fetch_equiv_papers.mjs
//
// Papers cover the experimental tests of the weak equivalence principle
// discussed in Lecture 1 (Newton pendulum -> MICROSCOPE satellite).
//
// Prerequisites:
//   1. TIB network access (VPN or on-campus) for institutional subscriptions.
//   2. Playwright installed in the sibling FQHE project:
//        /home/tobias/Projects/FQHE/node_modules/playwright
//   3. Run: node scripts/fetch_equiv_papers.mjs
//
// The script opens a headed Chromium window.  You may need to solve a
// Cloudflare or publisher captcha in the browser.  After that, all PDFs
// are fetched automatically.

import { chromium } from '/home/tobias/Projects/FQHE/node_modules/playwright/index.mjs';
import { writeFileSync, existsSync, mkdirSync } from 'fs';
import { resolve } from 'path';

const PAPERS_DIR = resolve(import.meta.dirname, '..', 'literature', 'equiv-principle');

const PAPERS = [
  {
    id: 'EP01',
    file: 'EP01_Eotvos_AnnPhys_1922.pdf',
    url: 'https://onlinelibrary.wiley.com/doi/pdfdirect/10.1002/andp.19223730903',
    triggerUrl: 'https://onlinelibrary.wiley.com/doi/10.1002/andp.19223730903',
    publisher: 'Wiley',
  },
  {
    id: 'EP02',
    file: 'EP02_Roll_Dicke_AnnPhys_1964.pdf',
    url: 'https://www.sciencedirect.com/science/article/pii/0003491664902593/pdf',
    triggerUrl: 'https://www.sciencedirect.com/science/article/pii/0003491664902593',
    publisher: 'Elsevier',
  },
  {
    id: 'EP03',
    file: 'EP03_Williams_CQG_2012.pdf',
    url: 'https://iopscience.iop.org/article/10.1088/0264-9381/29/18/184004/pdf',
    triggerUrl: 'https://iopscience.iop.org/article/10.1088/0264-9381/29/18/184004',
    publisher: 'IOP',
  },
  {
    id: 'EP04',
    file: 'EP04_Touboul_PRL_2022.pdf',
    url: 'https://journals.aps.org/prl/pdf/10.1103/PhysRevLett.129.121102',
    triggerUrl: 'https://journals.aps.org/prl/abstract/10.1103/PhysRevLett.129.121102',
    publisher: 'APS',
  },
  {
    id: 'EP05',
    file: 'EP05_Adelberger_PPNP_2009.pdf',
    url: 'https://www.sciencedirect.com/science/article/pii/S0146641008000720/pdfft',
    triggerUrl: 'https://www.sciencedirect.com/science/article/pii/S0146641008000720',
    publisher: 'Elsevier',
  },
];

// ---------------------------------------------------------------------------
// Publisher-specific Cloudflare / access detection
// ---------------------------------------------------------------------------

async function waitForPublisherPage(page, publisher, timeoutMs = 180000) {
  console.log(`Waiting for ${publisher} page to load (solve any challenges in the browser)...`);
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
      (document.title && document.title.includes('Class. Quantum Grav.')),
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
  };

  const check = checks[publisher] || checks.APS;

  try {
    await page.waitForFunction(check, { timeout: timeoutMs });
    const title = await page.title();
    console.log(`Page loaded: "${title}"`);
    console.log('Access confirmed!\n');
    await new Promise(r => setTimeout(r, 2000));
    return true;
  } catch (_) {
    return false;
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  mkdirSync(PAPERS_DIR, { recursive: true });

  // Check which papers still need downloading
  const todo = PAPERS.filter(p => !existsSync(resolve(PAPERS_DIR, p.file)));
  if (todo.length === 0) {
    console.log('All papers already downloaded. Nothing to do.');
    return;
  }

  console.log(`${todo.length}/${PAPERS.length} papers to download.\n`);
  console.log('Launching HEADED Chromium (persistent profile)...');
  console.log('Make sure TIB network access is active!\n');

  // Persistent context — cookies (Cloudflare, publisher sessions) survive across runs
  const userDataDir = resolve(PAPERS_DIR, '..', '.browser-profile');
  mkdirSync(userDataDir, { recursive: true });

  const context = await chromium.launchPersistentContext(userDataDir, {
    headless: false,
    args: ['--disable-blink-features=AutomationControlled'],
    viewport: { width: 1280, height: 900 },
  });
  const page = context.pages()[0] || await context.newPage();

  let downloaded = 0;
  let failed = 0;
  let skipped = 0;

  // Group papers by publisher so we only need one challenge per publisher
  const byPublisher = {};
  for (const paper of PAPERS) {
    (byPublisher[paper.publisher] ||= []).push(paper);
  }

  for (const [publisher, papers] of Object.entries(byPublisher)) {
    // Find the first paper in this group that still needs downloading
    const firstTodo = papers.find(p => !existsSync(resolve(PAPERS_DIR, p.file)));
    if (!firstTodo) {
      for (const p of papers) {
        console.log(`SKIP ${p.id}: ${p.file} (already exists)`);
        skipped++;
      }
      continue;
    }

    // Navigate to trigger page for this publisher
    console.log(`--- ${publisher} ---`);
    console.log(`Navigating to: ${firstTodo.triggerUrl}`);
    await page.goto(firstTodo.triggerUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });

    const passed = await waitForPublisherPage(page, publisher);
    if (!passed) {
      console.log(`WARNING: Could not confirm ${publisher} access. Trying downloads anyway...\n`);
    }

    // Download all papers from this publisher
    for (const paper of papers) {
      const outPath = resolve(PAPERS_DIR, paper.file);
      if (existsSync(outPath)) {
        console.log(`SKIP ${paper.id}: ${paper.file} (already exists)`);
        skipped++;
        continue;
      }

      try {
        process.stdout.write(`FETCH ${paper.id}: ${paper.file} ... `);

        // Try API request first (works for APS, IOP)
        let body = null;
        const response = await page.request.get(paper.url, { timeout: 30000 });
        if (response.status() === 200) {
          body = await response.body();
        }

        // If API request failed (403), download via browser navigation
        if (!body || body.slice(0, 5).toString() !== '%PDF-') {
          // Navigate to article page first (sets referer)
          await page.goto(paper.triggerUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
          await new Promise(r => setTimeout(r, 2000));

          // Try navigating directly to PDF URL (browser follows redirects, sends cookies+referer)
          const pdfResponse = await page.goto(paper.url, { waitUntil: 'commit', timeout: 30000 });
          if (pdfResponse && pdfResponse.status() === 200) {
            body = await pdfResponse.body();
          }
        }

        // If still no PDF, use publisher-specific download strategy
        if (!body || body.slice(0, 5).toString() !== '%PDF-') {
          if (publisher === 'Wiley') {
            // Wiley: click the PDF download link in the toolbar
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
                  const tmpPath = await download.path();
                  if (tmpPath) { const { readFileSync } = await import('fs'); body = readFileSync(tmpPath); break; }
                }
              } catch (_) { continue; }
            }
          } else if (publisher === 'Elsevier') {
            // Elsevier: navigate to article, find the PDF viewer link,
            // then intercept the real PDF from the CDN (pdf.sciencedirectassets.com)
            await page.goto(paper.triggerUrl, { waitUntil: 'load', timeout: 30000 });
            await new Promise(r => setTimeout(r, 3000));

            const pdfHref = await page.locator('a[href*="/pdf"]').first().getAttribute('href').catch(() => null);

            if (pdfHref) {
              const pdfUrl = pdfHref.startsWith('http') ? pdfHref : `https://www.sciencedirect.com${pdfHref}`;

              // Collect all responses with %PDF- header; the real one comes from the CDN
              const pdfPromise = new Promise((resolve) => {
                const timeout = setTimeout(() => resolve(null), 25000);
                const handler = async (resp) => {
                  try {
                    const b = await resp.body();
                    if (b.length > 1000 && b.slice(0, 5).toString() === '%PDF-') {
                      clearTimeout(timeout);
                      page.removeListener('response', handler);
                      resolve(b);
                    }
                  } catch (_) {}
                };
                page.on('response', handler);
              });

              await page.goto(pdfUrl, { waitUntil: 'load', timeout: 30000 }).catch(() => null);
              await new Promise(r => setTimeout(r, 5000)); // give PDF viewer time to fetch
              body = await pdfPromise;
            }
          }
        }

        if (!body) {
          console.log('FAIL (no PDF obtained)');
          failed++;
          continue;
        }

        const header = body.slice(0, 5).toString();
        if (header !== '%PDF-') {
          console.log(`FAIL (not a PDF, got: "${header}...")`);
          failed++;
          continue;
        }

        writeFileSync(outPath, body);
        console.log(`OK (${(body.length / 1024).toFixed(0)} KB)`);
        downloaded++;

        // Be polite: short delay between downloads
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
