// manifold.mjs — graph surface z = h(u, v) used by the lec03/lec04/lec05
// figures and demos, plus lift helpers (chart → R³) and an orthographic
// yaw+pitch projector that mirrors docs/tangent-basis.html.

// ── Surface ──────────────────────────────────────────────────────
// h(u, v) = 0.5 cos(0.9 u) + 0.35 sin(0.6 v)
export const surface = {
  h:  (u, v) => 0.5  * Math.cos(0.9 * u) + 0.35 * Math.sin(0.6 * v),
  hu: (u, _v) => -0.5 * 0.9 * Math.sin(0.9 * u),
  hv: (_u, v) =>  0.35 * 0.6 * Math.cos(0.6 * v),
};

// Lift a chart point.
export function lift(p) {
  return [p[0], p[1], surface.h(p[0], p[1])];
}

// Lift a chart-coord tangent vector at chart-point p:
// v_M = a · ∂_uΦ + b · ∂_vΦ where Φ(u,v) = (u, v, h(u,v)).
export function liftTangent(p, vChart) {
  const [u, v] = p;
  const [a, b] = vChart;
  return [a, b, a * surface.hu(u, v) + b * surface.hv(u, v)];
}

// Lift an entire chart polyline.
export function liftPath(path) {
  return path.map(lift);
}

// Lift a vector field at (u, v) — i.e. evaluate the field, then lift the
// resulting tangent vector.
export function liftField(field, u, v) {
  return liftTangent([u, v], [field.Vu(u, v), field.Vv(u, v)]);
}

// ── Yaw-then-pitch orthographic projector ────────────────────────
// Returns a function (x, y, z) -> [screenX, screenY, depth].
// Convention matches docs/tangent-basis.html:
//   x1 = x·cos(yaw) - y·sin(yaw)
//   y1 = x·sin(yaw) + y·cos(yaw)
//   y2 = y1·cos(pitch) - z·sin(pitch)
//   z2 = y1·sin(pitch) + z·cos(pitch)
//   return [x1, z2, y2]
// Larger depth = farther into the screen ⇒ paint smaller-depth-first
// for back-to-front order.  (yaw=0, pitch=0) projects +x to +X, +z to +Y.
export function makeProjector({ yaw, pitch }) {
  const cy = Math.cos(yaw),  sy = Math.sin(yaw);
  const cp = Math.cos(pitch), sp = Math.sin(pitch);
  return (x, y, z) => {
    const x1 = x * cy - y * sy;
    const y1 = x * sy + y * cy;
    const y2 = y1 * cp - z * sp;
    const z2 = y1 * sp + z * cp;
    return [x1, z2, y2];
  };
}
