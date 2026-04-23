// Tests for four_current.mjs — 4-current in 1+1d spacetime.
// Run: node docs/demos/four_current.test.mjs
import assert from 'node:assert/strict';
import {
  lcg,
  fieldPresets,
  seedParticles,
  rk4StepParticle,
  lorentzBoost,
  lorentzPredict,
  boostedBox,
  pointInParallelogram,
  clipChordToStrip,
  chordContribution,
  chordContributionBoosted,
  stepAndAccumulate,
  addDelta,
  newAccumulators,
  runningAverage,
} from './four_current.mjs';

const TOL = 1e-9;
let n = 0;
function ok(name) { console.log(`  ✓ ${name}`); n++; }

// (1) rk4StepParticle on a constant drift reproduces the closed form
// x(t) = x0 + v·t exactly, since RK4 is exact on linear ODEs.
{
  const vx = fieldPresets.drift;              // v = 0.3
  let p = { t: 0, x: 0, q: +1, id: 0 };
  const dt = 0.05;
  for (let i = 0; i < 40; i++) p = rk4StepParticle(p, vx, dt);
  assert(Math.abs(p.t - 2.0) < 1e-12, `t=${p.t}`);
  assert(Math.abs(p.x - 0.6) < 1e-12, `x=${p.x}, want 0.6`);
  ok('rk4StepParticle on constant drift is exact');
}

// (2) Lorentz boost round-trip: inv ∘ apply = id.
{
  const B = lorentzBoost(0.6);
  assert(Math.abs(B.gamma - 1.25) < 1e-12, `gamma=${B.gamma}`);
  const samples = [[0, 0], [1.7, -2.3], [-0.4, 3.1], [5.0, 5.0]];
  for (const [t, x] of samples) {
    const [tp, xp] = B.apply(t, x);
    const [t2, x2] = B.inv(tp, xp);
    assert(Math.abs(t2 - t) < 1e-12 && Math.abs(x2 - x) < 1e-12,
      `round-trip fail at (${t},${x}) → (${t2},${x2})`);
  }
  ok('Lorentz boost: inv ∘ apply = id');
}

// (3) Lorentz boost is area-preserving (det Λ = 1): a box of area A in
// S becomes a parallelogram of area A in S'.
{
  const B = lorentzBoost(0.5);
  const box = { xA: -1, xB: +1, t0: 0, t1: 3 };
  const c = boostedBox(box, B);
  // shoelace for quad
  const area =
    0.5 * Math.abs(
      c[0][0]*(c[1][1]-c[3][1]) +
      c[1][0]*(c[2][1]-c[0][1]) +
      c[2][0]*(c[3][1]-c[1][1]) +
      c[3][0]*(c[0][1]-c[2][1]));
  const A = (box.xB - box.xA) * (box.t1 - box.t0);
  assert(Math.abs(area - A) < 1e-12, `|R'|=${area}, |R|=${A}`);
  ok('boosted box preserves area');
}

// (4) clipChordToStrip: axis-aligned 1d clip.
{
  assert.deepEqual(clipChordToStrip(0, 10, 2, 7), [0.2, 0.7]);
  assert.deepEqual(clipChordToStrip(0, 10, -5, -1), null);
  assert.deepEqual(clipChordToStrip(5, 5, 0, 10), [0, 1]);  // no motion, inside
  assert.deepEqual(clipChordToStrip(5, 5, 6, 10), null);    // no motion, outside
  // reverse direction
  assert.deepEqual(clipChordToStrip(10, 0, 2, 7), [0.3, 0.8]);
  ok('clipChordToStrip 1d slab clip');
}

// (5) chordContribution: straight chord entirely inside returns
// (Δt, Δx); chord clipped at boundary returns the clipped portion.
{
  const box = { xA: -1, xB: +1, t0: 0, t1: 2 };
  const c1 = chordContribution(0.5, 0.0, 1.5, 0.4, box);
  assert(Math.abs(c1.dur - 1.0) < TOL && Math.abs(c1.dx - 0.4) < TOL, JSON.stringify(c1));

  // chord enters from x<−1, exits at x=+1: x(s) = −2 + 4s, so x = −1 at
  // s = 0.25 and x = +1 at s = 0.75. t(s) = 1 + 0s, so dur = (1−1)*0.5 = 0 (wait, Δt=0).
  // Use Δt != 0 instead.
  const c2 = chordContribution(0, -2, 1, 2, box);
  // t(s) = s; x(s) = -2 + 4s. Inside x∈[-1,1] ⇔ s∈[0.25, 0.75]. Δt=1·0.5, Δx=4·0.5.
  assert(Math.abs(c2.dur - 0.5) < TOL, `dur=${c2.dur}`);
  assert(Math.abs(c2.dx - 2.0) < TOL, `dx=${c2.dx}`);

  // chord entirely outside
  const c3 = chordContribution(0, 5, 1, 6, box);
  assert(c3.dur === 0 && c3.dx === 0, 'outside chord must contribute 0');
  ok('chordContribution (rest frame)');
}

// (6) pointInParallelogram: rest-frame corners form a rectangle; test
// a few points.
{
  const corners = [[0, -1], [0, 1], [2, 1], [2, -1]];  // t ∈ [0,2], x ∈ [-1,1]
  assert(pointInParallelogram(1, 0, corners));
  assert(pointInParallelogram(0, -1, corners));
  assert(!pointInParallelogram(-0.01, 0, corners));
  assert(!pointInParallelogram(1, 1.01, corners));
  ok('pointInParallelogram');
}

// (7) chordContributionBoosted against a rest-frame parallelogram
// should agree with chordContribution (since boost = identity).
{
  const box = { xA: -1, xB: +1, t0: 0, t1: 2 };
  const Bid = lorentzBoost(0);
  const corners = boostedBox(box, Bid);
  const rest = chordContribution(0, -2, 1, 2, box);
  const boosted = chordContributionBoosted(0, -2, 1, 2, corners);
  assert(Math.abs(rest.dur - boosted.dur) < 1e-6, `${rest.dur} vs ${boosted.dur}`);
  assert(Math.abs(rest.dx - boosted.dx) < 1e-6, `${rest.dx} vs ${boosted.dx}`);
  ok('boosted chord with β=0 matches rest-frame clip');
}

// (8) THE KEY PROPERTY. A single charged particle on a straight
// worldline contributes q·(Δτ, Δx) to (∫J^0, ∫J^1) inside the region,
// and this 2-vector should Lorentz-transform under β.
//   In S:  (Δt_R, Δx_R) ≡ (dur, dx)
//   In S': (Δt'_R, Δx'_R) = Λ(β)·(Δt_R, Δx_R)
// Equivalently: the chord within R, viewed from S', has dur'=γ(dur−β·dx)
// and dx'=γ(dx−β·dur). We verify by computing (dur', dx') directly in S'.
{
  const beta = 0.4;
  const B = lorentzBoost(beta);
  const box = { xA: -1, xB: +1, t0: 0, t1: 3 };
  const corners = boostedBox(box, B);

  // worldline of a particle at rest in S from (t=0, x=0.3) to (t=3, x=0.3)
  const rest = chordContribution(0, 0.3, 3, 0.3, box);
  const [tp0, xp0] = B.apply(0, 0.3);
  const [tp1, xp1] = B.apply(3, 0.3);
  const boosted = chordContributionBoosted(tp0, xp0, tp1, xp1, corners);

  const predicted = lorentzPredict(rest.dur, rest.dx, beta);
  // Important: our "2-current" convention uses (dur, dx) which
  // transforms as a contravariant 2-vector: (dt', dx') = Λ·(dt, dx).
  const exp_dur = B.gamma * (rest.dur - beta * rest.dx);
  const exp_dx  = B.gamma * (rest.dx  - beta * rest.dur);
  assert(Math.abs(boosted.dur - exp_dur) < 1e-5,
    `dur': got ${boosted.dur}, want ${exp_dur}`);
  assert(Math.abs(boosted.dx - exp_dx) < 1e-5,
    `dx':  got ${boosted.dx}, want ${exp_dx}`);
  // cross-check: lorentzPredict returns the same thing for this chord
  assert(Math.abs(predicted.eps - exp_dur) < 1e-12);
  assert(Math.abs(predicted.J   - exp_dx)  < 1e-12);
  ok('single-chord 2-current transforms as Λ · (dur, dx)');
}

// (9) Full batch: seed many particles, step for several dt, verify that
// the batch accumulator (A0, A1) in S and (A0p, A1p) in S' agree under Λ.
{
  const beta = 0.3;
  const B = lorentzBoost(beta);
  const rng = lcg(42);
  const box = { xA: -0.6, xB: +0.6, t0: 0, t1: 2.5 };
  const corners = boostedBox(box, B);
  const vx = fieldPresets.wavy;

  let particles = seedParticles(250, -2, 2, 0, 'pm1', rng);
  const acc = newAccumulators();
  const dt = 0.01;
  const steps = Math.round(box.t1 / dt);
  for (let k = 0; k < steps; k++) {
    const d = stepAndAccumulate(particles, vx, dt, box, B, corners);
    addDelta(acc, d);
    particles = d.next;
  }
  const avg = runningAverage(acc, box);
  const pred = lorentzPredict(avg.eps, avg.J, beta);
  // Tolerance: parallelogram clip uses 24 bisection iters + 16 samples;
  // with 250 particles over 2.5 units of time and 120 boundary events,
  // empirical residual should be small.
  assert(Math.abs(pred.eps - avg.epsP) < 2e-3,
    `ε̄ transform: Λ(S)=${pred.eps}, S'=${avg.epsP}`);
  assert(Math.abs(pred.J - avg.JP) < 2e-3,
    `J̄ transform: Λ(S)=${pred.J}, S'=${avg.JP}`);
  ok('batch (ε̄, J̄) transforms as 2-vector to ≤2e-3');
}

// (10) β = 0 degeneracy: rest and boosted accumulators must be exactly
// equal (same box, same particles, boost is identity).
{
  const B = lorentzBoost(0);
  const rng = lcg(7);
  const box = { xA: -0.5, xB: +0.5, t0: 0, t1: 1.5 };
  const corners = boostedBox(box, B);
  let particles = seedParticles(80, -1.5, 1.5, 0, 'pm1', rng);
  const acc = newAccumulators();
  const dt = 0.02;
  for (let k = 0; k < 75; k++) {
    const d = stepAndAccumulate(particles, fieldPresets.shear, dt, box, B, corners);
    addDelta(acc, d);
    particles = d.next;
  }
  // Boosted parallelogram clip uses bisection, so equality is approximate.
  assert(Math.abs(acc.A0 - acc.A0p) < 2e-4, `A0=${acc.A0}, A0p=${acc.A0p}`);
  assert(Math.abs(acc.A1 - acc.A1p) < 2e-4, `A1=${acc.A1}, A1p=${acc.A1p}`);
  ok('β=0 degeneracy: primed and unprimed accumulators agree');
}

// (11) Sign-flip: negating every charge flips both accumulators.
{
  const B = lorentzBoost(0.2);
  const box = { xA: -0.5, xB: +0.5, t0: 0, t1: 1.0 };
  const corners = boostedBox(box, B);
  const rng1 = lcg(11), rng2 = lcg(11);
  let pA = seedParticles(40, -1, 1, 0, 'pm1', rng1);
  let pB = seedParticles(40, -1, 1, 0, 'pm1', rng2).map(p => ({ ...p, q: -p.q }));
  const accA = newAccumulators(), accB = newAccumulators();
  const dt = 0.02;
  for (let k = 0; k < 50; k++) {
    const dA = stepAndAccumulate(pA, fieldPresets.drift, dt, box, B, corners);
    const dB = stepAndAccumulate(pB, fieldPresets.drift, dt, box, B, corners);
    addDelta(accA, dA); addDelta(accB, dB);
    pA = dA.next; pB = dB.next;
  }
  assert(Math.abs(accA.A0 + accB.A0) < 1e-12);
  assert(Math.abs(accA.A1 + accB.A1) < 1e-12);
  assert(Math.abs(accA.A0p + accB.A0p) < 1e-12);
  assert(Math.abs(accA.A1p + accB.A1p) < 1e-12);
  ok('sign-flip: q → −q inverts every accumulator');
}

// (12) Still field: ẋ=0 ⇒ J=0. Only ε contributes.
{
  const B = lorentzBoost(0);
  const box = { xA: -1, xB: +1, t0: 0, t1: 2 };
  const corners = boostedBox(box, B);
  const rng = lcg(3);
  let particles = seedParticles(60, -2, 2, 0, 'plus', rng);
  const acc = newAccumulators();
  const dt = 0.05;
  for (let k = 0; k < 40; k++) {
    const d = stepAndAccumulate(particles, fieldPresets.still, dt, box, B, corners);
    addDelta(acc, d); particles = d.next;
  }
  assert(Math.abs(acc.A1) < 1e-12, `J=0 for still field, got A1=${acc.A1}`);
  assert(acc.A0 > 0, 'A0 should be positive for all-+1 charges in a still field');
  ok('still field: J=0, ε>0');
}

// (13) Charge conservation: dQ == dCross for every step (exact, discrete).
{
  const B = lorentzBoost(0);
  const box = { xA: -0.5, xB: +0.5, t0: 0, t1: 3 };
  const corners = boostedBox(box, B);
  const rng = lcg(55);
  let particles = seedParticles(120, -1.5, 1.5, 0, 'pm1', rng);
  const dt = 0.02;
  let totalQ = 0, totalC = 0;
  for (let k = 0; k < 150; k++) {
    const d = stepAndAccumulate(particles, fieldPresets.wavy, dt, box, B, corners);
    // per-step: dQ must equal dCross
    assert(d.dQ === d.dCross, `step ${k}: dQ=${d.dQ}, dCross=${d.dCross}`);
    totalQ += d.dQ; totalC += d.dCross;
    particles = d.next;
  }
  assert(totalQ === totalC, `totals: Q=${totalQ}, Cross=${totalC}`);
  ok('∂_μ J^μ = 0 holds exactly in the discrete scheme');
}

// (14) runningAverage: volume cancellation is correct.
{
  const acc = { A0: 4, A1: 6, A0p: 2, A1p: 3 };
  const box = { xA: 0, xB: 2, t0: 0, t1: 1 };   // |R| = 2
  const r = runningAverage(acc, box);
  assert(r.eps === 2 && r.J === 3 && r.epsP === 1 && r.JP === 1.5);
  ok('runningAverage divides by (t1−t0)(xB−xA)');
}

// (15) seedParticles: honours chargeLaw 'neutral' (exact ±1 half-split)
//     and 'plus' (all +1).
{
  const rng = lcg(9);
  const N = 20;
  const all = seedParticles(N, 0, 1, 0, 'plus', rng);
  assert(all.every(p => p.q === +1));
  const half = seedParticles(N, 0, 1, 0, 'neutral', rng);
  const sum = half.reduce((s, p) => s + p.q, 0);
  assert(sum === 0, `'neutral' sum: got ${sum}, want 0`);
  ok('seedParticles respects chargeLaw');
}

console.log(`\nfour_current.mjs: ${n}/15 tests passed`);
