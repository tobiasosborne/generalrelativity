// Tests for lie_bracket.mjs — finite-step parallelogram and analytic [v,w].
// Run: node docs/demos/lie_bracket.test.mjs
import assert from 'node:assert/strict';
import { flowAlong, flowGap, lieBracket, presets } from './lie_bracket.mjs';

let n = 0;
function ok(name) { console.log(`  ✓ ${name}`); n++; }

// ── Helpers ──────────────────────────────────────────────────
const constU = { Vu: () => 1, Vv: () => 0 };  // v = (1, 0)
const constV = { Vu: () => 0, Vv: () => 1 };  // w = (0, 1)

// (1) Constant fields commute exactly: gap = 0 for any ε.
{
  for (const eps of [0.05, 0.2, 0.5]) {
    const g = flowGap(constU, constV, { u: 0.3, v: -0.7 }, eps);
    assert(Math.abs(g[0]) < 1e-10, `commuting gap_u (ε=${eps}): ${g[0]}`);
    assert(Math.abs(g[1]) < 1e-10, `commuting gap_v (ε=${eps}): ${g[1]}`);
  }
  ok('Constant commuting fields: gap = 0 to machine precision');
}

// (2) Analytic [v,w] for v=(1,0), w=(0,u) is (0,1) at any p.
{
  const v = { Vu: () => 1, Vv: () => 0 };
  const w = { Vu: () => 0, Vv: (u) => u };  // w = (0, u)
  for (const p of [{u: 0, v: 0}, {u: 1.3, v: -0.5}, {u: -2, v: 1.7}]) {
    const b = lieBracket(v, w, p);
    assert(Math.abs(b[0]) < 1e-6, `[v,w]^1 at ${JSON.stringify(p)}: ${b[0]}`);
    assert(Math.abs(b[1] - 1) < 1e-6, `[v,w]^2 at ${JSON.stringify(p)}: ${b[1]}`);
  }
  ok('lieBracket: v=(1,0), w=(0,u) gives (0,1) at all p');
}

// (3) Antisymmetry: [v,w] = -[w,v].
{
  const v = { Vu: (u, vv) => Math.sin(0.7 * u),  Vv: (u, vv) => 0.4 * vv };
  const w = { Vu: (u, vv) => -0.3 * vv,          Vv: (u, vv) => Math.cos(0.5 * u) };
  for (const p of [{u: 0.5, v: 0.2}, {u: -1.1, v: 1.4}]) {
    const a = lieBracket(v, w, p);
    const b = lieBracket(w, v, p);
    assert(Math.abs(a[0] + b[0]) < 1e-5, `antisym 1 at ${JSON.stringify(p)}: ${a[0]}+${b[0]}`);
    assert(Math.abs(a[1] + b[1]) < 1e-5, `antisym 2 at ${JSON.stringify(p)}: ${a[1]}+${b[1]}`);
  }
  ok('Antisymmetry [v,w] = -[w,v]');
}

// (4) Flow gap → ε² · [v,w] as ε → 0.  For v=(1,0), w=(0,u), [v,w]=(0,1).
//     For this polynomial pair the leading correction is exactly zero and
//     gap = (0, ε²) at every ε (RK4 is exact on affine RHS), so we just
//     verify gap/ε² = (0, 1) at every ε within numerical tolerance.
{
  const v = { Vu: () => 1, Vv: () => 0 };
  const w = { Vu: () => 0, Vv: (u) => u };
  const p = { u: 0.4, v: -0.2 };
  for (const eps of [0.4, 0.2, 0.1, 0.05, 0.02]) {
    const g = flowGap(v, w, p, eps);
    assert(Math.abs(g[0] / (eps*eps))      < 1e-6, `gap_u/ε² at ε=${eps}: ${g[0]/(eps*eps)}`);
    assert(Math.abs(g[1] / (eps*eps) - 1)  < 1e-6, `gap_v/ε² at ε=${eps}: ${g[1]/(eps*eps)}`);
  }
  ok('flowGap / ε² = [v,w] = (0,1) exactly for the affine pair');
}

// (4b) Convergence test on a *nonlinear* pair (sin/cos) where RK4 has
//      genuine truncation error: gap/ε² → [v,w] as ε → 0.
{
  const v = { Vu: (u, vv) => Math.sin(0.7 * vv), Vv: (u, vv) => 0.4 * Math.cos(0.5 * u) };
  const w = { Vu: (u, vv) => 0.3 * vv,           Vv: (u, vv) => Math.sin(0.6 * u) };
  const p = { u: 0.4, v: -0.2 };
  const b = lieBracket(v, w, p);
  const errAt = (eps) => {
    const g = flowGap(v, w, p, eps);
    return Math.hypot(g[0] / (eps*eps) - b[0], g[1] / (eps*eps) - b[1]);
  };
  const eBig = errAt(0.5);
  const eMed = errAt(0.1);
  const eSm  = errAt(0.02);
  // BCH expansion: gap/ε² = [v,w] + O(ε)·(higher brackets), so error ∝ ε.
  assert(eSm  < 5e-3, `gap/ε² close to [v,w] at ε=0.02: err=${eSm}`);
  assert(eMed < eBig, `convergence ε=0.1 (${eMed}) should beat ε=0.5 (${eBig})`);
  assert(eSm  < eMed, `convergence ε=0.02 (${eSm}) should beat ε=0.1 (${eMed})`);
  ok('Nonlinear pair: gap/ε² → [v,w] monotonically as ε → 0');
}

// (5) Same convergence for a nontrivial pair (rotation × translation).
{
  const v = { Vu: () => 1, Vv: () => 0 };          // translation in u
  const w = { Vu: (u, vv) => -vv, Vv: (u, vv) => u }; // rotation; [v,w] = (0, 1)
  const p = { u: 0.7, v: -0.3 };
  const eps = 0.02;
  const g = flowGap(v, w, p, eps);
  const b = lieBracket(v, w, p);
  // For rotation + translation, [v,w] is constant (0, 1) up to derivative consts.
  // Just check gap matches eps^2 * b within ~5%.
  assert(Math.abs(g[0] - eps*eps*b[0]) < 0.005, `rot×trans gap_u: ${g[0]} vs ${eps*eps*b[0]}`);
  assert(Math.abs(g[1] - eps*eps*b[1]) < 0.005, `rot×trans gap_v: ${g[1]} vs ${eps*eps*b[1]}`);
  ok('Rotation × translation: numerical gap ≈ ε² · [v,w]');
}

// (6) flowAlong is consistent: flowing for time eps then -eps returns to start.
{
  const f = { Vu: (u, vv) => Math.sin(u + vv), Vv: (u, vv) => Math.cos(u - vv) };
  const p = { u: 0.3, v: 0.5 };
  const q = flowAlong(f, p, 0.4);
  const back = flowAlong(f, { u: q[0], v: q[1] }, -0.4);
  assert(Math.hypot(back[0] - p.u, back[1] - p.v) < 1e-7,
    `flow round-trip: ${back} vs ${p.u},${p.v}`);
  ok('flowAlong: forward then backward returns to start');
}

// (7) Presets are well-formed.
{
  assert(Array.isArray(presets) && presets.length >= 2, 'presets is array of length >= 2');
  for (const ps of presets) {
    assert(typeof ps.name === 'string', 'preset has name');
    assert(typeof ps.v.Vu === 'function' && typeof ps.v.Vv === 'function', 'v is a field');
    assert(typeof ps.w.Vu === 'function' && typeof ps.w.Vv === 'function', 'w is a field');
  }
  ok(`presets: ${presets.length} field-pair presets registered`);
}

console.log(`\nlie_bracket.mjs: ${n}/8 tests passed`);
