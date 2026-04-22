// Tests for covector.mjs — covector as level sets, ω(v) action, crossings.
// Run: node docs/demos/covector.test.mjs
import assert from 'node:assert/strict';
import { apply, crossingsCount, levelSegment, levelSets } from './covector.mjs';

let n = 0;
function ok(name) { console.log(`  ✓ ${name}`); n++; }

const TOL = 1e-12;

// (1) apply: ω(v) = ω·v.
{
  assert.strictEqual(apply([3, 4], [1, 0]), 3);
  assert.strictEqual(apply([3, 4], [0, 1]), 4);
  assert.strictEqual(apply([3, 4], [2, 5]), 26);
  assert.strictEqual(apply([0, 0], [7, 9]), 0);
  ok('apply: ω(v) = ω₁v¹ + ω₂v²');
}

// (2) Linearity: ω(v + w) = ω(v) + ω(w).
{
  const omega = [1.7, -0.3];
  const v = [0.4, 1.2], w = [-1.1, 2.5];
  const sum = [v[0] + w[0], v[1] + w[1]];
  assert(Math.abs(apply(omega, sum) - (apply(omega, v) + apply(omega, w))) < TOL);
  ok('Linearity: ω(v + w) = ω(v) + ω(w)');
}

// (3) Scaling: ω(c·v) = c·ω(v).
{
  const omega = [2, -1];
  const v = [1.3, 0.7];
  for (const c of [-3, -1, 0, 0.5, 4]) {
    assert(Math.abs(apply(omega, [c*v[0], c*v[1]]) - c * apply(omega, v)) < TOL);
  }
  ok('Scaling: ω(c·v) = c·ω(v)');
}

// (4) levelSegment(ω, k, box) returns endpoints on the line ω·x = k that
//     lie inside the box.  For ω = (1, 0), the line is u = k vertical.
{
  const seg = levelSegment([1, 0], 1.0, { umin: -2, umax: 2, vmin: -2, vmax: 2 });
  assert(seg !== null, 'segment should exist for u=1 inside [-2,2]²');
  const [a, b] = seg;
  assert(Math.abs(a[0] - 1) < TOL && Math.abs(b[0] - 1) < TOL,
    `u-coords on line: ${a}, ${b}`);
  // The two points should span the box vertically (-2 to 2)
  assert(Math.abs(Math.abs(a[1] - b[1]) - 4) < TOL, `length: ${Math.abs(a[1]-b[1])}`);
  ok('levelSegment: ω=(1,0), k=1 spans u=1 vertical inside box');
}

// (5) levelSegment returns null when the level k is outside reach of the box.
{
  const seg = levelSegment([1, 0], 99, { umin: -2, umax: 2, vmin: -2, vmax: 2 });
  assert.strictEqual(seg, null, 'no segment for unreachable k');
  ok('levelSegment: returns null when level lies outside box');
}

// (6) levelSegment for an oblique covector ω = (1, 1).  Line u + v = 0
//     should pass diagonally; endpoints are (-2, 2) and (2, -2).
{
  const seg = levelSegment([1, 1], 0, { umin: -2, umax: 2, vmin: -2, vmax: 2 });
  assert(seg !== null);
  // Each endpoint must satisfy u + v = 0 and lie on a box boundary.
  for (const pt of seg) {
    assert(Math.abs(pt[0] + pt[1]) < 1e-9, `on line: ${pt}`);
    const onBoundary =
      Math.abs(pt[0] - (-2)) < 1e-9 || Math.abs(pt[0] - 2) < 1e-9 ||
      Math.abs(pt[1] - (-2)) < 1e-9 || Math.abs(pt[1] - 2) < 1e-9;
    assert(onBoundary, `endpoint on boundary: ${pt}`);
  }
  ok('levelSegment: oblique ω=(1,1), k=0 gives box-diagonal segment');
}

// (7) levelSets returns one segment per integer k in the requested range.
{
  const segs = levelSets([1, 0], { umin: -2.5, umax: 2.5, vmin: -2, vmax: 2 }, 3);
  // For ω = (1, 0), integer k in {-3..3} that fit inside [-2.5, 2.5]:
  // k = -2, -1, 0, 1, 2  => 5 segments.
  assert.strictEqual(segs.length, 5, `count: got ${segs.length}, want 5`);
  for (const s of segs) assert(s.points && s.k !== undefined);
  ok('levelSets: 5 integer segments for ω=(1,0) in box [-2.5, 2.5]');
}

// (8) crossingsCount(ω, v): segment from 0 to v crosses one integer
//     level set per integer in the range (0, ω(v)] (signed).
{
  // ω = (1, 0), v = (3.5, 0): ω(v) = 3.5.  Crossings at u = 1, 2, 3 ⇒ 3.
  assert.strictEqual(crossingsCount([1, 0], [3.5, 0]), 3);
  // Negative direction: v = (-2.5, 0), crossings at u = -1, -2 ⇒ -2.
  assert.strictEqual(crossingsCount([1, 0], [-2.5, 0]), -2);
  // Zero: ω(v) = 0 ⇒ no crossings.
  assert.strictEqual(crossingsCount([1, -1], [1, 1]), 0);
  // Oblique: ω = (1, 1), v = (1.7, 1.4) ⇒ ω(v) = 3.1, crossings = 3.
  assert.strictEqual(crossingsCount([1, 1], [1.7, 1.4]), 3);
  ok('crossingsCount: signed integer count = ⌊ω(v)⌋ direction-aware');
}

console.log(`\ncovector.mjs: ${n}/8 tests passed`);
