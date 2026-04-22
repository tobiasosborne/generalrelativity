// flow.mjs — RK4 integrator for a 2D vector field on chart coordinates.
// Used by D1 (click-and-flow) and D3 (fluid-flow swarm).
//
// The default field matches scripts/sim_lec05_flow.jl exactly so the
// interactive demo and the static figure in lec05.tex are consistent.

export const defaultField = {
  Vu: (u, v) => 0.85 + 0.15 * v,
  Vv: (u, _v) => 0.55 * Math.cos(0.7 * u),
};

export function rk4Step(u, v, h, Vu, Vv) {
  const k1u = Vu(u, v);
  const k1v = Vv(u, v);
  const k2u = Vu(u + 0.5 * h * k1u, v + 0.5 * h * k1v);
  const k2v = Vv(u + 0.5 * h * k1u, v + 0.5 * h * k1v);
  const k3u = Vu(u + 0.5 * h * k2u, v + 0.5 * h * k2v);
  const k3v = Vv(u + 0.5 * h * k2u, v + 0.5 * h * k2v);
  const k4u = Vu(u + h * k3u, v + h * k3v);
  const k4v = Vv(u + h * k3u, v + h * k3v);
  return [
    u + (h / 6) * (k1u + 2 * k2u + 2 * k3u + k4u),
    v + (h / 6) * (k1v + 2 * k2v + 2 * k3v + k4v),
  ];
}

// Integrate forward from (u0, v0) for parameter range [0, tEnd] in
// nominal step h.  Returns Array<[u, v]> with N+1 entries where
// N = round(tEnd / h); the actual step is dt = tEnd / N so the final
// node corresponds exactly to t = tEnd.
export function integrate(u0, v0, tEnd, h, Vu, Vv) {
  const N = Math.max(1, Math.round(Math.abs(tEnd) / h));
  const dt = tEnd / N;
  const path = new Array(N + 1);
  path[0] = [u0, v0];
  let u = u0, v = v0;
  for (let i = 0; i < N; i++) {
    [u, v] = rk4Step(u, v, dt, Vu, Vv);
    path[i + 1] = [u, v];
  }
  return path;
}

// Linearly interpolate a path that uniformly spans parameter [0, tEnd].
// Clamps outside the range.
export function sampleAt(path, tEnd, t) {
  const N = path.length - 1;
  if (N < 1) return path[0].slice();
  if (t <= 0) return path[0].slice();
  if (t >= tEnd) return path[N].slice();
  const idxF = (t / tEnd) * N;
  const i = Math.floor(idxF);
  const a = idxF - i;
  return [
    path[i][0] * (1 - a) + path[i + 1][0] * a,
    path[i][1] * (1 - a) + path[i + 1][1] * a,
  ];
}
