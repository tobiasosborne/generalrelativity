// lower_index.mjs — symmetric 2×2 metric tensor: construction from
// eigendecomposition, inverse, flat (V → V*), sharp (V* → V), and the
// quadratic form g(v, v).

// Build g from eigenvalues (λ1, λ2) and eigenframe rotation θ.
// g = R · diag(λ1, λ2) · R^T  with  R = [[cosθ, -sinθ], [sinθ, cosθ]].
export function metricFromEig(l1, l2, theta) {
  const c = Math.cos(theta), s = Math.sin(theta);
  const a = l1 * c * c + l2 * s * s;
  const d = l1 * s * s + l2 * c * c;
  const b = (l1 - l2) * c * s;
  return [[a, b], [b, d]];
}

export function det(g) {
  return g[0][0] * g[1][1] - g[0][1] * g[1][0];
}

// Inverse of a symmetric 2×2 matrix.
export function inverse(g) {
  const D = det(g);
  if (Math.abs(D) < 1e-14) throw new Error('metric is singular');
  return [
    [ g[1][1] / D, -g[0][1] / D ],
    [-g[1][0] / D,  g[0][0] / D ],
  ];
}

// Flat: lower an index.  ω_a = g_ab · v^b.
export function flat(g, v) {
  return [
    g[0][0] * v[0] + g[0][1] * v[1],
    g[1][0] * v[0] + g[1][1] * v[1],
  ];
}

// Sharp: raise an index.  v^a = g^{ab} · ω_b.
export function sharp(g, omega) {
  const gi = inverse(g);
  return [
    gi[0][0] * omega[0] + gi[0][1] * omega[1],
    gi[1][0] * omega[0] + gi[1][1] * omega[1],
  ];
}

// g(v, v) = v^a · g_ab · v^b.
export function gQuad(g, v) {
  return g[0][0] * v[0] * v[0] + 2 * g[0][1] * v[0] * v[1] + g[1][1] * v[1] * v[1];
}
