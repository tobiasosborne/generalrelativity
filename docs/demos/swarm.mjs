// swarm.mjs — many-particle advection on a fixed 2D vector field.
// Reuses RK4 from flow.mjs.

import { rk4Step, defaultField } from './flow.mjs';

// Linear-congruential RNG for deterministic seeds.
function lcg(seed) {
  let s = (seed | 0) || 1;
  return () => {
    s = (s * 1103515245 + 12345) | 0;
    return ((s >>> 16) & 0x7fff) / 0x7fff;
  };
}

// Seed N particles uniformly inside box {umin..umax} × {vmin..vmax}.
export function seed(N, box, rngSeed = 1) {
  const r = lcg(rngSeed);
  const out = new Array(N);
  const du = box.umax - box.umin;
  const dv = box.vmax - box.vmin;
  for (let i = 0; i < N; i++) {
    out[i] = [box.umin + r() * du, box.vmin + r() * dv];
  }
  return out;
}

// Advance every particle by parameter dt, using N RK4 substeps.
// Returns a fresh array (does not mutate input).
export function advance(particles, field, dt, N = 1) {
  const sub = dt / N;
  const out = new Array(particles.length);
  for (let i = 0; i < particles.length; i++) {
    let u = particles[i][0], v = particles[i][1];
    for (let k = 0; k < N; k++) {
      [u, v] = rk4Step(u, v, sub, field.Vu, field.Vv);
    }
    out[i] = [u, v];
  }
  return out;
}

// Built-in field presets.
export const presets = [
  {
    name: 'Default (lec05 field)',
    field: defaultField,
  },
  {
    name: 'Rigid rotation',
    field: { Vu: (u, v) => -v, Vv: (u, v) => u },
  },
  {
    name: 'Saddle (hyperbolic)',
    field: { Vu: (u, v) => u, Vv: (u, v) => -v },
  },
  {
    name: 'Source',
    field: { Vu: (u, v) => 0.4 * u, Vv: (u, v) => 0.4 * v },
  },
  {
    name: 'Sink',
    field: { Vu: (u, v) => -0.4 * u, Vv: (u, v) => -0.4 * v },
  },
  {
    name: 'Shear',
    field: { Vu: (u, v) => v, Vv: () => 0 },
  },
  {
    name: 'Vortex pair',
    field: {
      Vu: (u, v) => -(v - 1) / (1 + (u - 1) ** 2 + (v - 1) ** 2)
                    + (v + 1) / (1 + (u + 1) ** 2 + (v + 1) ** 2),
      Vv: (u, v) =>  (u - 1) / (1 + (u - 1) ** 2 + (v - 1) ** 2)
                    - (u + 1) / (1 + (u + 1) ** 2 + (v + 1) ** 2),
    },
  },
];
