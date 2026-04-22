// Tests for lower_index.mjs — metric construction, flat (V→V*) and
// sharp (V*→V), round-trip identity.
// Run: node docs/demos/lower_index.test.mjs
import assert from 'node:assert/strict';
import { metricFromEig, det, inverse, flat, sharp, gQuad } from './lower_index.mjs';

let n = 0;
function ok(name) { console.log(`  ✓ ${name}`); n++; }
const TOL = 1e-10;

function near(a, b, t = TOL) { return Math.abs(a - b) < t; }
function matNear(A, B, t = TOL) {
  return near(A[0][0], B[0][0], t) && near(A[0][1], B[0][1], t)
      && near(A[1][0], B[1][0], t) && near(A[1][1], B[1][1], t);
}

// (1) metricFromEig(λ1, λ2, θ=0) returns diag(λ1, λ2).
{
  const g = metricFromEig(2, 3, 0);
  assert(near(g[0][0], 2));
  assert(near(g[1][1], 3));
  assert(near(g[0][1], 0));
  assert(near(g[1][0], 0));
  ok('metricFromEig: θ=0 yields diag(λ1, λ2)');
}

// (2) metricFromEig: rotated eigenframe (45° CCW) of (1, 3).
//     R(45°) diag(1, 3) R(45°)^T = [[2, -1], [-1, 2]].
//     (Direct calc: a = 1·½+3·½ = 2, d = 1·½+3·½ = 2, b = (1−3)·½ = −1.)
{
  const g = metricFromEig(1, 3, Math.PI / 4);
  assert(near(g[0][0], 2));
  assert(near(g[1][1], 2));
  assert(near(g[0][1], -1));
  assert(near(g[1][0], -1));
  ok('metricFromEig: 45° rotation of diag(1,3) gives [[2,-1],[-1,2]]');
}

// (3) Symmetry: g[0][1] = g[1][0] for any (λ1, λ2, θ).
{
  for (const [l1, l2, th] of [[1, 1, 0.3], [-1, 2, 1.1], [3, -2, -0.5]]) {
    const g = metricFromEig(l1, l2, th);
    assert(near(g[0][1], g[1][0]),
      `symmetry: ${g[0][1]} vs ${g[1][0]} for (${l1},${l2},${th})`);
  }
  ok('metricFromEig: symmetric for any eigenvalues + rotation');
}

// (4) det = λ1·λ2 (rotation preserves determinant).
{
  for (const [l1, l2, th] of [[2, 3, 0], [1, -1, 0.6], [-2, -5, -1.2]]) {
    const g = metricFromEig(l1, l2, th);
    assert(near(det(g), l1 * l2),
      `det: got ${det(g)}, want ${l1 * l2}`);
  }
  ok('det(g) = λ1·λ2 (rotation invariant)');
}

// (5) inverse: g·g⁻¹ = I.
{
  const g = metricFromEig(1, 3, 0.4);
  const gi = inverse(g);
  const prod = [
    [g[0][0]*gi[0][0] + g[0][1]*gi[1][0], g[0][0]*gi[0][1] + g[0][1]*gi[1][1]],
    [g[1][0]*gi[0][0] + g[1][1]*gi[1][0], g[1][0]*gi[0][1] + g[1][1]*gi[1][1]],
  ];
  assert(matNear(prod, [[1,0],[0,1]]), `g·g⁻¹: ${JSON.stringify(prod)}`);
  ok('inverse: g·g⁻¹ = I');
}

// (6) flat / sharp on identity metric: ω equals v componentwise.
{
  const g = [[1, 0], [0, 1]];
  const v = [2.4, -1.7];
  const ω = flat(g, v);
  assert(near(ω[0], v[0]) && near(ω[1], v[1]),
    `flat(I, v) = v: ${ω}`);
  const w2 = sharp(g, ω);
  assert(near(w2[0], v[0]) && near(w2[1], v[1]),
    `sharp(I, ω) = v`);
  ok('flat/sharp on identity metric is the identity');
}

// (7) flat on diag(2, 3): v=(1, 1) ↦ ω=(2, 3).
{
  const g = metricFromEig(2, 3, 0);
  const v = [1, 1];
  const ω = flat(g, v);
  assert(near(ω[0], 2) && near(ω[1], 3), `flat: ${ω}`);
  ok('flat on diag(2,3): v=(1,1) ↦ ω=(2,3)');
}

// (8) Round-trip: sharp(g, flat(g, v)) = v for any nondegenerate g.
{
  const g = metricFromEig(1.7, -0.6, 0.7);  // mixed signature, rotated
  for (const v of [[1, 0], [0, 1], [1.3, -2.1]]) {
    const round = sharp(g, flat(g, v));
    assert(near(round[0], v[0]) && near(round[1], v[1]),
      `round-trip: ${round} vs ${v}`);
  }
  ok('Round-trip sharp ∘ flat = id for nondegenerate g');
}

// (9) gQuad(g, v) = g(v, v) = v · (g · v).
{
  const g = metricFromEig(2, 3, 0);
  const v = [1, 1];
  // Expected: 2·1·1 + 3·1·1 = 5
  assert(near(gQuad(g, v), 5));
  // For rotated diag(1, -1) (=Lorentzian) and v on the light cone,
  // g(v, v) = 0:
  const gL = metricFromEig(1, -1, 0);
  assert(near(gQuad(gL, [1, 1]), 0));
  assert(near(gQuad(gL, [1, -1]), 0));
  ok('gQuad: matches v·(g·v) and gives 0 on light cone (Lorentzian)');
}

console.log(`\nlower_index.mjs: ${n}/9 tests passed`);
