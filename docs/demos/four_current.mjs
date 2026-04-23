// four_current.mjs — interactive 4-current in 1+1d spacetime.
// Units c = 1. Coordinates (t, x).
//
// Public surface:
//   fieldPresets       — timelike 2-velocity fields v^x(t,x), |v^x|<1
//   lcg                — deterministic RNG (exported for tests/host)
//   seedParticles      — Poisson-in-x seeding at a given t
//   rk4StepParticle    — advance one particle by dt along ẋ = v^x(t,x)
//   lorentzBoost       — {gamma, apply, inv} for β ∈ (−1, 1)
//   boostedBox         — rest-frame worldtube → 4 corner images in S'
//   pointInParallelogram — in-parallelogram test (4 CCW corners)
//   clipChordToStrip   — 1d clip of [aIn, aOut] against [min, max] axis
//   chordContribution  — (dur, Δx) of a worldline segment inside a box
//   accumulate         — update accumulators over one time-step for all
//                        particles, in both frames
//   runningAverage     — (ε̄, J̄) from accumulators and region volume
//   lorentzPredict     — Λ(β) applied to a 2-current (ε, J)
//   chargeConservation — ∂_t Q_R(t) − flux_through_boundary
//
// Convention: the "rest-frame box" R is a spatial interval [x_a, x_b]
// observed over sim time [0, τ]. In S' the same worldtube is a
// parallelogram with corners Λ(β)·(t, x_{a|b}) at t = 0 and t = τ.

// ──────────────────────────────────────────────────────────────
// RNG

export function lcg(seed) {
  let s = (seed | 0) || 1;
  return () => {
    s = (s * 1103515245 + 12345) | 0;
    return ((s >>> 16) & 0x7fff) / 0x7fff;
  };
}

// ──────────────────────────────────────────────────────────────
// Fields: v^x(t, x) with |v^x| < 1 for all (t, x).
// Each entry returns a function so presets can be swapped at runtime.

export const fieldPresets = {
  drift:         (t, x) => 0.30,
  shear:         (t, x) => 0.55 * Math.tanh(0.60 * x),
  wavy:          (t, x) => 0.50 * Math.sin(0.80 * x + 0.40 * t),
  fountain:      (t, x) => 0.55 * Math.sin(1.10 * x) * Math.cos(0.35 * t),
  counterstream: (t, x) => 0.55 * Math.tanh(1.20 * x),
  still:         (t, x) => 0.00,
};

// ──────────────────────────────────────────────────────────────
// Particles. A particle is an object {t, x, q, id} with t monotone
// increasing along its worldline. We step (t, x) forward together:
// dt/ds = 1, dx/ds = v^x(t, x).

export function rk4StepParticle(p, vx, dt) {
  const t = p.t, x = p.x;
  const k1 = vx(t,             x);
  const k2 = vx(t + 0.5 * dt,  x + 0.5 * dt * k1);
  const k3 = vx(t + 0.5 * dt,  x + 0.5 * dt * k2);
  const k4 = vx(t +       dt,  x +       dt * k3);
  return {
    ...p,
    t: t + dt,
    x: x + (dt / 6) * (k1 + 2 * k2 + 2 * k3 + k4),
  };
}

// Seed N particles at time t=t0, x ~ Uniform[xMin, xMax], charges per
// chargeLaw ∈ {'plus', 'pm1', 'neutral'}.
//   plus    — all q = +1
//   pm1     — q ∈ {+1, -1} each with p=1/2
//   neutral — same as pm1 but ensures exact neutrality for even N
export function seedParticles(N, xMin, xMax, t0, chargeLaw, rng, idStart = 0) {
  const out = new Array(N);
  const dx = xMax - xMin;
  for (let i = 0; i < N; i++) {
    const q = chargeForLaw(chargeLaw, rng, i, N);
    out[i] = { t: t0, x: xMin + rng() * dx, q, id: idStart + i };
  }
  return out;
}

function chargeForLaw(law, rng, i, N) {
  if (law === 'plus')    return +1;
  if (law === 'pm1')     return rng() < 0.5 ? +1 : -1;
  if (law === 'neutral') return i < (N >>> 1) ? +1 : -1; // half ±1 exactly
  return +1;
}

// ──────────────────────────────────────────────────────────────
// Lorentz boost. β = velocity of S' relative to S; a point with
// velocity β in S is at rest in S'. t' = γ(t − βx), x' = γ(x − βt).

export function lorentzBoost(beta) {
  if (!(beta > -1 && beta < 1)) {
    throw new RangeError(`beta=${beta} must lie in (−1, 1)`);
  }
  const gamma = 1 / Math.sqrt(1 - beta * beta);
  return {
    beta,
    gamma,
    apply: (t, x) => [gamma * (t - beta * x), gamma * (x - beta * t)],
    inv:   (tp, xp) => [gamma * (tp + beta * xp), gamma * (xp + beta * tp)],
  };
}

// Lorentz-transform a 2-current (ε, J) from S to S'.
export function lorentzPredict(eps, J, beta) {
  const g = 1 / Math.sqrt(1 - beta * beta);
  return {
    eps: g * (eps - beta * J),
    J:   g * (J   - beta * eps),
  };
}

// ──────────────────────────────────────────────────────────────
// Region geometry.
// A rest-frame worldtube is box = {xA, xB, t0, t1} interpreted as
// {(t, x) : xA ≤ x ≤ xB, t0 ≤ t ≤ t1}.
// Its image in S' under boost is the parallelogram with corners
// (in CCW order for β=0):
//   P0 = Λ(t0, xA),  P1 = Λ(t0, xB),  P2 = Λ(t1, xB),  P3 = Λ(t1, xA).
// For β > 0 the ordering stays CCW; we rely on pointInParallelogram
// which works for any convex-quad labelling.

export function boostedBox(box, boost) {
  return [
    boost.apply(box.t0, box.xA),
    boost.apply(box.t0, box.xB),
    boost.apply(box.t1, box.xB),
    boost.apply(box.t1, box.xA),
  ];
}

// Signed double-area of triangle (a, b, c) in 2d.
function cross2(ax, ay, bx, by, cx, cy) {
  return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}

// Point-in-convex-quad test for corners in either winding. EPS allows
// boundary inclusion. Returns true if the point lies inside or on edge.
export function pointInParallelogram(tp, xp, corners, eps = 1e-12) {
  let sign = 0;
  for (let i = 0; i < 4; i++) {
    const a = corners[i], b = corners[(i + 1) & 3];
    const c = cross2(a[0], a[1], b[0], b[1], tp, xp);
    if (c >  eps) { if (sign < 0) return false; sign = +1; }
    if (c < -eps) { if (sign > 0) return false; sign = -1; }
  }
  return true;
}

// ──────────────────────────────────────────────────────────────
// Chord accounting. Over a short simulation step, particle j moves
// from (t0, x0) to (t1, x1) approximately along a straight chord in
// spacetime (valid to O(dt²), matching RK4 accuracy in the position).
//
// In the rest frame, the relevant clip is against a box
//   T ∈ [box.t0, box.t1]  AND  X ∈ [box.xA, box.xB].
// clipChordToStrip returns the sub-interval [sIn, sOut] ⊂ [0, 1] of
// the chord parameter s that lies inside a 1d slab [vmin, vmax] along
// one axis. Intersection of two such intervals gives the 2d clip.

export function clipChordToStrip(a0, a1, vmin, vmax) {
  // parameterise chord as a(s) = a0 + s*(a1 - a0), s ∈ [0,1]
  const da = a1 - a0;
  if (Math.abs(da) < 1e-15) {
    // no motion along this axis; whole chord is in or out
    return (a0 >= vmin && a0 <= vmax) ? [0, 1] : null;
  }
  let sLo = (vmin - a0) / da;
  let sHi = (vmax - a0) / da;
  if (sLo > sHi) { const t = sLo; sLo = sHi; sHi = t; }
  const sIn  = Math.max(0, sLo);
  const sOut = Math.min(1, sHi);
  return sIn < sOut ? [sIn, sOut] : null;
}

// Intersection of two [lo, hi] intervals, or null.
function intersect01(a, b) {
  if (!a || !b) return null;
  const lo = Math.max(a[0], b[0]);
  const hi = Math.min(a[1], b[1]);
  return lo < hi ? [lo, hi] : null;
}

// Contribution of a single chord to (∫ J^0, ∫ J^1) over a rest-frame
// box: returns {dur, dx} where dur is the coordinate time spent inside
// and dx is the net spatial displacement within the box. Multiply by
// charge q to get per-particle contributions.
export function chordContribution(t0, x0, t1, x1, box) {
  const clipT = clipChordToStrip(t0, t1, box.t0, box.t1);
  const clipX = clipChordToStrip(x0, x1, box.xA, box.xB);
  const s = intersect01(clipT, clipX);
  if (!s) return { dur: 0, dx: 0 };
  const ds = s[1] - s[0];
  return {
    dur: (t1 - t0) * ds,
    dx:  (x1 - x0) * ds,
  };
}

// Chord contribution against a boosted parallelogram in S'.
// Strategy: transform chord endpoints to S', then clip against the
// parallelogram by bisection on the parameter s (monotone-in-s).
// The parallelogram is convex, so pointInParallelogram(·) is a
// monotone indicator per chord direction; we locate entry/exit by
// sampling + refining.
export function chordContributionBoosted(tp0, xp0, tp1, xp1, corners) {
  // Sample 17 points; find contiguous inside-run; refine boundaries.
  const N = 16;
  const inside = new Array(N + 1);
  for (let i = 0; i <= N; i++) {
    const s = i / N;
    const tp = tp0 + s * (tp1 - tp0);
    const xp = xp0 + s * (xp1 - xp0);
    inside[i] = pointInParallelogram(tp, xp, corners);
  }
  // find first and last "true"
  let i0 = -1, i1 = -1;
  for (let i = 0; i <= N; i++) {
    if (inside[i]) { if (i0 < 0) i0 = i; i1 = i; }
  }
  if (i0 < 0) return { dur: 0, dx: 0 };

  // Refine entry (between i0-1 and i0) and exit (between i1 and i1+1).
  const refine = (iOutside, iInside) => {
    if (iOutside < 0 || iOutside > N) return iInside / N;
    let sLo = iOutside / N, sHi = iInside / N;
    for (let k = 0; k < 24; k++) {
      const sm = 0.5 * (sLo + sHi);
      const tm = tp0 + sm * (tp1 - tp0);
      const xm = xp0 + sm * (xp1 - xp0);
      if (pointInParallelogram(tm, xm, corners)) sHi = sm;
      else sLo = sm;
    }
    return 0.5 * (sLo + sHi);
  };
  const sIn  = i0 === 0 ? 0 : refine(i0 - 1, i0);
  const sOut = i1 === N ? 1 : refine(i1 + 1, i1);
  const ds = Math.max(0, sOut - sIn);
  return {
    dur: (tp1 - tp0) * ds,
    dx:  (xp1 - xp0) * ds,
  };
}

// ──────────────────────────────────────────────────────────────
// Accumulators.
//
// acc = {
//   A0, A1,              // Σ q_j × (dur, dx) inside rest box
//   A0p, A1p,            // same inside boosted box (primed frame)
//   tauRest, tauBoost,   // "elapsed sim time" weights ≡ box width_t
// }
// Volumes |R| = (t1 − t0) × (xB − xA) in S; same value in S' because
// Lorentz transforms are area-preserving in 1+1d (det Λ = 1).

export function newAccumulators() {
  return { A0: 0, A1: 0, A0p: 0, A1p: 0 };
}

// One advection step: move each particle from its current state to
// p_next via rk4StepParticle; accumulate chord contributions; return
// {next, dA0, dA1, dA0p, dA1p, dQ, dCross} where dQ is the net change
// in "charge currently inside rest spatial window [xA, xB]" and dCross
// is the signed sum of boundary crossings (+1 in, −1 out, by charge).
// ∂_μ J^μ = 0 ⇒ dQ == dCross (discrete exact, up to chord-straightness).
export function stepAndAccumulate(particles, vx, dt, box, boost, boostedCorners) {
  const next = new Array(particles.length);
  let dA0 = 0, dA1 = 0, dA0p = 0, dA1p = 0;
  let dQ = 0, dCross = 0;
  for (let i = 0; i < particles.length; i++) {
    const p = particles[i];
    const q = rk4StepParticle(p, vx, dt);
    next[i] = q;

    // Spacetime-average accumulators (rest frame box).
    const rest = chordContribution(p.t, p.x, q.t, q.x, box);
    dA0 += p.q * rest.dur;
    dA1 += p.q * rest.dx;

    // Boosted-frame accumulators.
    if (boost && boostedCorners) {
      const [tp0, xp0] = boost.apply(p.t, p.x);
      const [tp1, xp1] = boost.apply(q.t, q.x);
      const b = chordContributionBoosted(tp0, xp0, tp1, xp1, boostedCorners);
      dA0p += p.q * b.dur;
      dA1p += p.q * b.dx;
    }

    // Conservation: compare net change in Q_W (inside spatial window
    // [xA, xB] at the current slice) to signed boundary crossings.
    const in0 = p.x >= box.xA && p.x <= box.xB;
    const in1 = q.x >= box.xA && q.x <= box.xB;
    if (in1 && !in0) dQ += p.q;
    if (in0 && !in1) dQ -= p.q;
    // Crossings of xA / xB as the chord is traversed, signed by direction.
    dCross += p.q * (crossingSign(p.x, q.x, box.xA) - crossingSign(p.x, q.x, box.xB));
    // Explanation of the two minus signs:
    //   · cross xA rightward (x goes from <xA to >xA): particle enters W,
    //     crossingSign(xA) = +1, contributes +q.
    //   · cross xB rightward: particle leaves W, crossingSign(xB) = +1,
    //     contributes −q (the extra − in front).
    // Net: +q for any inward crossing, −q for any outward crossing.
  }
  return { next, dA0, dA1, dA0p, dA1p, dQ, dCross };
}

// +1 if the chord x(s) = x0 + s(x1−x0) crosses level c rightward
// (x0 < c ≤ x1), −1 if leftward (x0 ≥ c > x1), 0 otherwise.
function crossingSign(x0, x1, c) {
  if (x0 < c && x1 >= c) return +1;
  if (x0 >= c && x1 < c) return -1;
  return 0;
}

// Convenience: fold a delta into an acc in place.
export function addDelta(acc, d) {
  acc.A0  += d.dA0;
  acc.A1  += d.dA1;
  acc.A0p += d.dA0p;
  acc.A1p += d.dA1p;
  return acc;
}

// Running spacetime-averaged 2-current.
//   ε̄ = A0 / |R|,  J̄ = A1 / |R|  with  |R| = (t1 − t0)(xB − xA)
export function runningAverage(acc, box) {
  const vol = (box.t1 - box.t0) * (box.xB - box.xA);
  if (vol <= 0) return { eps: 0, J: 0, epsP: 0, JP: 0, vol };
  return {
    eps:  acc.A0  / vol,
    J:    acc.A1  / vol,
    epsP: acc.A0p / vol,   // |R'| = |R| in 1+1d
    JP:   acc.A1p / vol,
    vol,
  };
}

// ──────────────────────────────────────────────────────────────
// Charge conservation diagnostic.
// For a spatial window W = [xA, xB] (infinite in time), the continuity
// equation ∂_t ε + ∂_x J = 0 integrates to
//   dQ_W(t)/dt = J(t, xA) − J(t, xB)
// Accumulating over [t0, t1]:
//   Q_W(t1) − Q_W(t0) = ∫ dt [J(t,xA) − J(t,xB)]
// The diagnostic returns (lhs, rhs, residual) computed from running
// counters maintained by the host render loop.

export function chargeConservationResidual(Q_t0, Q_t1, fluxLeftAcc, fluxRightAcc) {
  const lhs = Q_t1 - Q_t0;
  const rhs = fluxLeftAcc - fluxRightAcc;
  return { lhs, rhs, residual: lhs - rhs };
}
