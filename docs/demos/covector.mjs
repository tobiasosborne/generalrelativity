// covector.mjs — covector ω as a stack of parallel level lines on R²,
// the action ω(v) = ω·v, and the signed crossing-count interpretation.
//
// All inputs are 2-tuples [a, b].

// ω(v) = ω₁·v¹ + ω₂·v²
export function apply(omega, v) {
  return omega[0] * v[0] + omega[1] * v[1];
}

// Level segment: clip the line {x ∈ R² : ω·x = k} to the given box.
// Returns [[u0,v0], [u1,v1]] or null if the line misses the box entirely.
//
// Parametrise the line as x(t) = x0 + t·d where d ⟂ ω, |d|=1, and
// x0 is any point on the line.  Then walk t through values that put
// x inside the box.
export function levelSegment(omega, k, box) {
  const [a, b] = omega;
  const norm2 = a*a + b*b;
  if (norm2 === 0) return null;
  // Foot of perpendicular from origin onto ω·x = k:
  const t0 = k / norm2;
  const x0 = [a * t0, b * t0];
  // Direction perpendicular to ω, normalised:
  const dn = Math.sqrt(norm2);
  const d = [-b / dn, a / dn];

  // Clip line x = x0 + t·d to the box.  Solve four 1D constraints:
  //   x0[0] + t·d[0] ∈ [umin, umax]
  //   x0[1] + t·d[1] ∈ [vmin, vmax]
  let tmin = -Infinity, tmax = Infinity;
  const slabs = [
    [d[0], box.umin - x0[0], box.umax - x0[0]],
    [d[1], box.vmin - x0[1], box.vmax - x0[1]],
  ];
  for (const [dk, lo, hi] of slabs) {
    if (Math.abs(dk) < 1e-12) {
      // Line parallel to this axis; require lo <= 0 <= hi.
      if (lo > 0 || hi < 0) return null;
    } else {
      let a1 = lo / dk, a2 = hi / dk;
      if (a1 > a2) [a1, a2] = [a2, a1];
      if (a1 > tmin) tmin = a1;
      if (a2 < tmax) tmax = a2;
    }
  }
  if (tmin > tmax) return null;
  const p = [x0[0] + tmin * d[0], x0[1] + tmin * d[1]];
  const q = [x0[0] + tmax * d[0], x0[1] + tmax * d[1]];
  return [p, q];
}

// All integer level segments fitting inside the box.  kRange caps the
// search for efficiency; we walk integers k = -kRange..+kRange.
export function levelSets(omega, box, kRange = 8) {
  const out = [];
  for (let k = -kRange; k <= kRange; k++) {
    const seg = levelSegment(omega, k, box);
    if (seg !== null) out.push({ k, points: seg });
  }
  return out;
}

// Signed integer count of level lines crossed by the segment 0 → v.
// Equals the number of integers strictly between 0 and ω(v)
// (or its negation when ω(v) < 0).
export function crossingsCount(omega, v) {
  const val = apply(omega, v);
  if (val === 0) return 0;
  if (val > 0) return Math.floor(val);
  return -Math.floor(-val);  // = -⌊|val|⌋ for val<0
}
