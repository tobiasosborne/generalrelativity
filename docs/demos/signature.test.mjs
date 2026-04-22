// Tests for signature.mjs — locus {v : g(v,v) = 1} as eigenvalues vary.
// Run: node docs/demos/signature.test.mjs
import assert from 'node:assert/strict';
import {
  signatureLabel, kindOfCurve, unitLocusPolylines, evalQuad,
} from './signature.mjs';

let n = 0;
function ok(name) { console.log(`  ✓ ${name}`); n++; }
const TOL = 1e-9;
function near(a, b, t = TOL) { return Math.abs(a - b) < t; }

// (1) signatureLabel for the canonical cases.
{
  assert.strictEqual(signatureLabel(1, 1),  '(+, +)');
  assert.strictEqual(signatureLabel(1, -1), '(+, −)');
  assert.strictEqual(signatureLabel(-1, -1),'(−, −)');
  assert.strictEqual(signatureLabel(0, 1),  '(0, +)');
  assert.strictEqual(signatureLabel(0, 0),  '(0, 0)');
  ok('signatureLabel: standard signs');
}

// (2) kindOfCurve classifies the locus shape.
{
  assert.strictEqual(kindOfCurve(2, 3),    'ellipse');
  assert.strictEqual(kindOfCurve(1, -1),   'hyperbola');
  assert.strictEqual(kindOfCurve(-2, 3),   'hyperbola');
  assert.strictEqual(kindOfCurve(-1, -1),  'empty');
  assert.strictEqual(kindOfCurve(0, 1),    'parallel-lines');
  assert.strictEqual(kindOfCurve(1, 0),    'parallel-lines');
  assert.strictEqual(kindOfCurve(0, -1),   'empty');
  assert.strictEqual(kindOfCurve(0, 0),    'empty');
  ok('kindOfCurve: ellipse/hyperbola/parallel-lines/empty cases');
}

// (3) Riemannian (1, 1, 0): unit circle — every sampled point satisfies
//     u² + v² ≈ 1 and lies inside the bounding box.
{
  const polys = unitLocusPolylines(1, 1, 0, { umin: -3, umax: 3, vmin: -3, vmax: 3 }, 200);
  assert.strictEqual(polys.length, 1, 'one connected component');
  for (const p of polys[0]) {
    assert(near(p[0]*p[0] + p[1]*p[1], 1, 1e-6),
      `on unit circle: ${p}, r²=${p[0]*p[0] + p[1]*p[1]}`);
  }
  ok('Riemannian (1,1): locus is the unit circle');
}

// (4) Anisotropic Riemannian (4, 1, 0): semi-axes 1/2 in u, 1 in v.
//     Specifically (0.5, 0) and (0, 1) are on the locus.
{
  const polys = unitLocusPolylines(4, 1, 0, { umin: -3, umax: 3, vmin: -3, vmax: 3 }, 400);
  // Verify all sampled points satisfy the ellipse equation.
  for (const p of polys[0]) {
    assert(near(4*p[0]*p[0] + p[1]*p[1], 1, 1e-5),
      `on ellipse: ${p}, q=${4*p[0]*p[0] + p[1]*p[1]}`);
  }
  ok('Anisotropic (4,1): locus is the ellipse 4u² + v² = 1');
}

// (5) Lorentzian (1, -1, 0): hyperbola x² − y² = 1 (two branches).
{
  const polys = unitLocusPolylines(1, -1, 0, { umin: -3, umax: 3, vmin: -3, vmax: 3 }, 400);
  assert(polys.length >= 2, `expected 2 branches, got ${polys.length}`);
  for (const poly of polys) {
    for (const p of poly) {
      assert(near(p[0]*p[0] - p[1]*p[1], 1, 1e-5),
        `hyperbola point: ${p}`);
    }
  }
  // Branches should be on opposite sides of u=0
  const xs = polys.map(p => p.map(q => q[0]).reduce((a,b) => a + b, 0) / p.length);
  assert(xs.some(x => x > 0) && xs.some(x => x < 0), 'two branches on opposite sides');
  ok('Lorentzian (1,-1): locus is two-branch hyperbola u²−v²=1');
}

// (6) Negative-definite (-1, -1, 0): empty locus.
{
  const polys = unitLocusPolylines(-1, -1, 0, { umin: -3, umax: 3, vmin: -3, vmax: 3 }, 100);
  assert.strictEqual(polys.length, 0, 'empty for negative-definite');
  ok('Negative definite (-1,-1): locus is empty');
}

// (7) Rotation invariance: the locus computed at θ is the rotated
//     image of the θ=0 locus.  Point on locus(θ) is R(θ)·(point on locus(0)).
{
  const th = 0.7;
  const polys0 = unitLocusPolylines(2, 0.5, 0,  { umin: -3, umax: 3, vmin: -3, vmax: 3 }, 64);
  const polysT = unitLocusPolylines(2, 0.5, th, { umin: -3, umax: 3, vmin: -3, vmax: 3 }, 64);
  const c = Math.cos(th), s = Math.sin(th);
  // Spot-check: every rotated point should satisfy g_θ on the locus,
  // confirmed by the points obeying rotated quadratic.
  for (const p of polysT[0]) {
    // unrotate; should land near locus0
    const u0 =  c*p[0] + s*p[1];
    const v0 = -s*p[0] + c*p[1];
    assert(near(2*u0*u0 + 0.5*v0*v0, 1, 1e-5),
      `rotated locus point unrotates to original: ${p} -> (${u0},${v0})`);
  }
  ok('Rotation invariance: locus(θ) = R(θ)·locus(0)');
}

// (8) evalQuad: evalQuad(l1, l2, theta, v) = g(v, v) with that g.
{
  // Identity g, v=(1,1) → 2.
  assert(near(evalQuad(1, 1, 0, [1, 1]), 2));
  // Diag(2, 3), v=(1, 1) → 5.
  assert(near(evalQuad(2, 3, 0, [1, 1]), 5));
  // Lorentzian v on light cone → 0.
  assert(near(evalQuad(1, -1, 0, [1, 1]), 0));
  ok('evalQuad: g(v, v) matches expected values');
}

console.log(`\nsignature.mjs: ${n}/8 tests passed`);
