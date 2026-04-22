// signature.mjs — locus {v ∈ R² : g(v, v) = 1} as the metric eigenvalues
// (λ1, λ2) and eigenframe rotation θ vary.  Returns disconnected pieces
// as separate polylines so the caller can draw them without bridging.

import { metricFromEig, gQuad } from './lower_index.mjs';

const ZERO = 1e-10;

export function signLabel(x) {
  if (x > ZERO)  return '+';
  if (x < -ZERO) return '−';
  return '0';
}

export function signatureLabel(l1, l2) {
  return `(${signLabel(l1)}, ${signLabel(l2)})`;
}

export function kindOfCurve(l1, l2) {
  const s1 = Math.sign(Math.abs(l1) < ZERO ? 0 : l1);
  const s2 = Math.sign(Math.abs(l2) < ZERO ? 0 : l2);
  if (s1 ===  1 && s2 ===  1) return 'ellipse';
  if (s1 === -1 && s2 === -1) return 'empty';
  if (s1 ===  0 && s2 ===  0) return 'empty';
  if ((s1 === 1 && s2 === -1) || (s1 === -1 && s2 === 1)) return 'hyperbola';
  // One zero, one nonzero
  if (s1 === 0 && s2 === 1)  return 'parallel-lines';
  if (s1 === 1 && s2 === 0)  return 'parallel-lines';
  // Remaining: one zero, one negative ⇒ no solution to s²·v² = 1 for sign<0
  return 'empty';
}

export function evalQuad(l1, l2, theta, v) {
  return gQuad(metricFromEig(l1, l2, theta), v);
}

// Return the locus as an array of polylines.  Each polyline is an array
// of [u, v] points.  Curves that leave the box on one side and re-enter
// elsewhere (hyperbola branches in particular) appear as separate
// polylines.
export function unitLocusPolylines(l1, l2, theta, box, samples = 400) {
  const g = metricFromEig(l1, l2, theta);
  const a = g[0][0], b = g[0][1], d = g[1][1];
  const insideBox = (p) =>
    p[0] >= box.umin && p[0] <= box.umax && p[1] >= box.vmin && p[1] <= box.vmax;

  const points = new Array(samples);  // null where direction has no real solution
  for (let i = 0; i < samples; i++) {
    const ang = (i / samples) * 2 * Math.PI;
    const c = Math.cos(ang), s = Math.sin(ang);
    const q = a*c*c + 2*b*c*s + d*s*s;
    if (q <= ZERO) { points[i] = null; continue; }
    const r = 1 / Math.sqrt(q);
    const p = [r * c, r * s];
    if (!insideBox(p)) { points[i] = null; continue; }
    points[i] = p;
  }

  // Split into runs of consecutive non-null points (with wrap-around).
  // This handles ellipse (one closed loop) and hyperbola (two arcs).
  const polys = [];
  let cur = null;
  // Find a starting null to break the loop neatly; if all non-null
  // (closed curve), start at i=0 and join end to start.
  let firstNull = -1;
  for (let i = 0; i < samples; i++) {
    if (points[i] === null) { firstNull = i; break; }
  }
  if (firstNull < 0) {
    // Fully closed loop — append a copy of the first point to close it.
    const arr = points.slice();
    arr.push(arr[0]);
    polys.push(arr);
    return polys;
  }
  for (let off = 0; off < samples; off++) {
    const i = (firstNull + off) % samples;
    if (points[i] !== null) {
      if (cur === null) cur = [];
      cur.push(points[i]);
    } else {
      if (cur && cur.length >= 2) polys.push(cur);
      cur = null;
    }
  }
  if (cur && cur.length >= 2) polys.push(cur);
  return polys;
}
