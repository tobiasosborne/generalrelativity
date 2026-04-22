// Tests for swarm.mjs — many-particle advection on a fixed field.
// Run: node docs/demos/swarm.test.mjs
import assert from 'node:assert/strict';
import { seed, advance, presets } from './swarm.mjs';

let n = 0;
function ok(name) { console.log(`  ✓ ${name}`); n++; }

// (1) seed() returns the requested number of particles, all in the
//     specified [umin, umax] × [vmin, vmax] box.
{
  const ps = seed(150, { umin: -2, umax: 2, vmin: -1.5, vmax: 1.5 }, 42);
  assert.strictEqual(ps.length, 150, 'count');
  for (const p of ps) {
    assert(p[0] >= -2 && p[0] <= 2, `u in range: ${p[0]}`);
    assert(p[1] >= -1.5 && p[1] <= 1.5, `v in range: ${p[1]}`);
  }
  ok('seed: 150 particles inside the box');
}

// (2) seed() is deterministic given the same RNG seed.
{
  const a = seed(50, { umin: 0, umax: 1, vmin: 0, vmax: 1 }, 777);
  const b = seed(50, { umin: 0, umax: 1, vmin: 0, vmax: 1 }, 777);
  for (let i = 0; i < 50; i++) {
    assert(Math.abs(a[i][0] - b[i][0]) < 1e-15);
    assert(Math.abs(a[i][1] - b[i][1]) < 1e-15);
  }
  ok('seed is deterministic for fixed RNG seed');
}

// (3) Constant field V=(1,0): after advance by dt = 0.5, every
//     particle's u shifts by exactly 0.5; v unchanged.
{
  const field = { Vu: () => 1, Vv: () => 0 };
  const initial = [[0, 0], [1, 1], [-2, 0.5]];
  const next = advance(initial, field, 0.5, 1);
  assert.strictEqual(next.length, 3);
  assert(Math.abs(next[0][0] - 0.5) < 1e-12);
  assert(Math.abs(next[0][1]) < 1e-12);
  assert(Math.abs(next[1][0] - 1.5) < 1e-12);
  assert(Math.abs(next[1][1] - 1) < 1e-12);
  assert(Math.abs(next[2][0] - (-1.5)) < 1e-12);
  assert(Math.abs(next[2][1] - 0.5) < 1e-12);
  ok('advance: constant field translates every particle exactly');
}

// (4) Bounded field: positions remain finite over many steps.
{
  const field = presets[0].field;  // default lec05 field
  let ps = seed(50, { umin: -2, umax: 2, vmin: -2, vmax: 2 }, 1);
  for (let step = 0; step < 200; step++) {
    ps = advance(ps, field, 0.05, 1);
  }
  for (const p of ps) {
    assert(Number.isFinite(p[0]) && Number.isFinite(p[1]),
      `non-finite at step 200: ${p}`);
  }
  ok('advance: bounded field keeps positions finite over 200 steps');
}

// (5) advance with N substeps gives same result as N×1-substep calls
//     within RK4 tolerance.
{
  const field = { Vu: (u, v) => Math.cos(u + v), Vv: (u, v) => Math.sin(u - v) };
  const ps0 = [[0.3, -0.2]];
  const dt = 0.4;
  const oneShot = advance(ps0, field, dt, 8);
  let ps = ps0;
  for (let i = 0; i < 8; i++) ps = advance(ps, field, dt / 8, 1);
  assert(Math.hypot(oneShot[0][0] - ps[0][0],
                    oneShot[0][1] - ps[0][1]) < 1e-9,
    `substep equivalence: ${oneShot[0]} vs ${ps[0]}`);
  ok('advance: substep count is internally consistent');
}

// (6) presets are well-formed.
{
  assert(presets.length >= 2);
  for (const ps of presets) {
    assert(typeof ps.name === 'string');
    assert(typeof ps.field.Vu === 'function');
    assert(typeof ps.field.Vv === 'function');
  }
  ok(`${presets.length} swarm presets registered`);
}

console.log(`\nswarm.mjs: ${n}/6 tests passed`);
