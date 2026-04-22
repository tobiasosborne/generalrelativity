// lie_bracket.mjs — finite-step parallelogram Φ_v ∘ Φ_w vs Φ_w ∘ Φ_v
// and the analytic Lie bracket [v,w]^j = v^i ∂_i w^j − w^i ∂_i v^j.
//
// Used by D2 (Lie-bracket parallelogram).

import { rk4Step } from './flow.mjs';

// Flow point p along field f for parameter eps; uses N RK4 substeps.
// eps may be negative (backward flow).
export function flowAlong(f, p, eps, N = 64) {
  const dt = eps / N;
  let u = p.u, v = p.v;
  for (let i = 0; i < N; i++) {
    [u, v] = rk4Step(u, v, dt, f.Vu, f.Vv);
  }
  return [u, v];
}

// Gap A − B where
//   A = Φ_w(eps, Φ_v(eps, p))  (v then w)
//   B = Φ_v(eps, Φ_w(eps, p))  (w then v)
// To leading order the gap is eps^2 * [v,w]|_p.
export function flowGap(v, w, p, eps, N = 64) {
  const half1 = flowAlong(v, p, eps, N);
  const A = flowAlong(w, { u: half1[0], v: half1[1] }, eps, N);
  const half2 = flowAlong(w, p, eps, N);
  const B = flowAlong(v, { u: half2[0], v: half2[1] }, eps, N);
  return [A[0] - B[0], A[1] - B[1]];
}

// Endpoints A, B and intermediate points (for drawing the open
// parallelogram with both legs).
export function legPaths(v, w, p, eps, N = 24) {
  const dt = eps / N;
  // Leg "v then w"
  const path1a = [[p.u, p.v]];
  let u = p.u, vv = p.v;
  for (let i = 0; i < N; i++) {
    [u, vv] = rk4Step(u, vv, dt, v.Vu, v.Vv);
    path1a.push([u, vv]);
  }
  const startB = { u, v: vv };
  const path1b = [[startB.u, startB.v]];
  for (let i = 0; i < N; i++) {
    [u, vv] = rk4Step(u, vv, dt, w.Vu, w.Vv);
    path1b.push([u, vv]);
  }
  const A = [u, vv];

  // Leg "w then v"
  const path2a = [[p.u, p.v]];
  u = p.u; vv = p.v;
  for (let i = 0; i < N; i++) {
    [u, vv] = rk4Step(u, vv, dt, w.Vu, w.Vv);
    path2a.push([u, vv]);
  }
  const path2b = [[u, vv]];
  for (let i = 0; i < N; i++) {
    [u, vv] = rk4Step(u, vv, dt, v.Vu, v.Vv);
    path2b.push([u, vv]);
  }
  const B = [u, vv];
  return { path1a, path1b, path2a, path2b, A, B };
}

// Numerical [v, w]^j = v^i ∂_i w^j − w^i ∂_i v^j at p
// using centred finite differences.
export function lieBracket(v, w, p, h = 1e-4) {
  const partial = (f, comp, axis) => {
    if (axis === 'u') {
      return (f[comp](p.u + h, p.v) - f[comp](p.u - h, p.v)) / (2 * h);
    } else {
      return (f[comp](p.u, p.v + h) - f[comp](p.u, p.v - h)) / (2 * h);
    }
  };
  const vu = v.Vu(p.u, p.v), vv = v.Vv(p.u, p.v);
  const wu = w.Vu(p.u, p.v), wv = w.Vv(p.u, p.v);
  // ∂_u w^1, ∂_v w^1, ∂_u v^1, ∂_v v^1, etc.
  const dwu_du = partial(w, 'Vu', 'u');
  const dwu_dv = partial(w, 'Vu', 'v');
  const dwv_du = partial(w, 'Vv', 'u');
  const dwv_dv = partial(w, 'Vv', 'v');
  const dvu_du = partial(v, 'Vu', 'u');
  const dvu_dv = partial(v, 'Vu', 'v');
  const dvv_du = partial(v, 'Vv', 'u');
  const dvv_dv = partial(v, 'Vv', 'v');
  const b1 = vu * dwu_du + vv * dwu_dv - (wu * dvu_du + wv * dvu_dv);
  const b2 = vu * dwv_du + vv * dwv_dv - (wu * dvv_du + wv * dvv_dv);
  return [b1, b2];
}

// Built-in field-pair presets.  Each one has a clean analytic [v,w]
// for a quick "expected vs measured" comparison in the demo.
export const presets = [
  {
    name: 'translate × shear',
    desc: 'v = (1, 0), w = (0, u) — [v,w] = (0, 1) constant',
    v: { Vu: () => 1, Vv: () => 0 },
    w: { Vu: () => 0, Vv: (u) => u },
  },
  {
    name: 'translate × rotate',
    desc: 'v = (1, 0), w = (−v, u) — [v,w] = (0, 1)',
    v: { Vu: () => 1, Vv: () => 0 },
    w: { Vu: (u, v) => -v, Vv: (u, v) => u },
  },
  {
    name: 'shear × shear',
    desc: 'v = (v, 0), w = (0, u) — [v,w] = (−v, u)',
    v: { Vu: (u, v) => v, Vv: () => 0 },
    w: { Vu: () => 0, Vv: (u) => u },
  },
  {
    name: 'commuting',
    desc: 'v = (1, 0), w = (0, 1) — [v,w] = 0 (gap = 0 always)',
    v: { Vu: () => 1, Vv: () => 0 },
    w: { Vu: () => 0, Vv: () => 1 },
  },
];
