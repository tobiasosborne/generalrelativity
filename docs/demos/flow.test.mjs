// Tests for flow.mjs — RK4 integrator on a 2D vector field.
// Run: node docs/demos/flow.test.mjs
import assert from 'node:assert/strict';
import { rk4Step, integrate, sampleAt, defaultField } from './flow.mjs';

const TOL = 1e-6;
let n = 0;
function ok(name) { console.log(`  ✓ ${name}`); n++; }

// (1) RK4 on du/dt = u with u(0) = 1 over [0, 1] hits e to 1e-8.
{
  const Vu = (u, _v) => u;
  const Vv = (_u, _v) => 0;
  const path = integrate(1.0, 0.0, 1.0, 0.001, Vu, Vv);
  const e = path[path.length - 1][0];
  assert(Math.abs(e - Math.E) < 1e-8, `e: got ${e}, want ${Math.E}`);
  ok('RK4 du/dt=u over [0,1] gives e within 1e-8');
}

// (2) Constant field V = (1, 0) translates exactly: u(t) = u0 + t.
{
  const Vu = () => 1, Vv = () => 0;
  const path = integrate(0.0, 0.0, 3.7, 0.05, Vu, Vv);
  const last = path[path.length - 1];
  assert(Math.abs(last[0] - 3.7) < TOL, `u: got ${last[0]}, want 3.7`);
  assert(Math.abs(last[1] - 0.0) < TOL, `v: got ${last[1]}, want 0`);
  ok('Constant V=(1,0) translates exactly');
}

// (3) Group property: integrating from p to t1, then from there to t2,
//     should equal integrating from p directly to t1 + t2.
{
  const Vu = defaultField.Vu, Vv = defaultField.Vv;
  const t1 = 1.2, t2 = 1.5;
  const path1 = integrate(-1.5, 0.4, t1, 0.005, Vu, Vv);
  const mid = path1[path1.length - 1];
  const path2 = integrate(mid[0], mid[1], t2, 0.005, Vu, Vv);
  const composed = path2[path2.length - 1];

  const pathDirect = integrate(-1.5, 0.4, t1 + t2, 0.005, Vu, Vv);
  const direct = pathDirect[pathDirect.length - 1];

  assert(Math.abs(composed[0] - direct[0]) < 1e-5,
    `group u: composed=${composed[0]}, direct=${direct[0]}`);
  assert(Math.abs(composed[1] - direct[1]) < 1e-5,
    `group v: composed=${composed[1]}, direct=${direct[1]}`);
  ok('Group property Φ_t2 ∘ Φ_t1 = Φ_{t1+t2} agrees within 1e-5');
}

// (4) Default field matches the closed form used in the static figure
//     and the lec05 simulation.
{
  const u = 0.4, v = -1.1;
  const expectedVu = 0.85 + 0.15 * v;
  const expectedVv = 0.55 * Math.cos(0.7 * u);
  assert(Math.abs(defaultField.Vu(u, v) - expectedVu) < 1e-12,
    `Vu(${u},${v}) = ${defaultField.Vu(u,v)}, want ${expectedVu}`);
  assert(Math.abs(defaultField.Vv(u, v) - expectedVv) < 1e-12,
    `Vv(${u},${v}) = ${defaultField.Vv(u,v)}, want ${expectedVv}`);
  ok('defaultField matches sim_lec05_flow.jl closed form');
}

// (5) sampleAt(t) interpolates between path nodes (linear is fine).
{
  const Vu = () => 1, Vv = () => 0;
  const tEnd = 4.0;
  const path = integrate(0.0, 0.0, tEnd, 0.04, Vu, Vv);
  const p = sampleAt(path, tEnd, 1.7);
  assert(Math.abs(p[0] - 1.7) < 1e-9, `sampleAt u at t=1.7: ${p[0]}`);
  assert(Math.abs(p[1]) < 1e-9, `sampleAt v at t=1.7: ${p[1]}`);
  // Boundary clamps
  const pStart = sampleAt(path, tEnd, -1);
  const pEnd   = sampleAt(path, tEnd, 999);
  assert(Math.abs(pStart[0]) < 1e-12);
  assert(Math.abs(pEnd[0] - 4.0) < 1e-9);
  // Mid-step interpolation when t doesn't land on a node
  const tEnd2 = 4.0;
  const path2 = integrate(0.0, 0.0, tEnd2, 0.07, Vu, Vv); // dt won't equal 0.07
  const pMid = sampleAt(path2, tEnd2, 2.5);
  assert(Math.abs(pMid[0] - 2.5) < 1e-9, `sampleAt mid: ${pMid[0]}`);
  ok('sampleAt linearly interpolates and clamps');
}

console.log(`\nflow.mjs: ${n}/5 tests passed`);
