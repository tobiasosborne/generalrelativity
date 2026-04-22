// Tests for manifold.mjs — surface h(u,v), lift helpers, yaw-pitch projector.
// Run: node docs/demos/manifold.test.mjs
import assert from 'node:assert/strict';
import {
  surface, lift, liftTangent, liftPath, liftField, makeProjector,
} from './manifold.mjs';

let n = 0;
function ok(name) { console.log(`  ✓ ${name}`); n++; }
const TOL = 1e-9;
function near(a, b, t = TOL) { return Math.abs(a - b) < t; }
function vNear(a, b, t = TOL) {
  return a.length === b.length && a.every((x, i) => near(x, b[i], t));
}

// (1) Surface matches the closed form used by the static figures and
//     sim_lec05_flow.jl: h(u,v) = 0.5 cos(0.9 u) + 0.35 sin(0.6 v).
{
  assert(near(surface.h(0, 0),  0.5));                    // 0.5·1 + 0.35·0
  assert(near(surface.h(0, Math.PI / 1.2), 0.85));         // 0.5·1 + 0.35·1
  assert(near(surface.h(Math.PI / 0.9, 0), -0.5));         // 0.5·(-1) + 0.35·0
  assert(near(surface.h(Math.PI / 0.9, Math.PI / 1.2), -0.15));  // -0.5 + 0.35
  ok('surface.h matches the lec03/04/05 closed form');
}

// (2) Analytic partials match centered finite differences.
{
  const eps = 1e-6;
  const tol = 1e-7;
  for (const [u, v] of [[0, 0], [0.7, -0.3], [-1.4, 1.1], [2.1, 0.9]]) {
    const huFD = (surface.h(u + eps, v) - surface.h(u - eps, v)) / (2 * eps);
    const hvFD = (surface.h(u, v + eps) - surface.h(u, v - eps)) / (2 * eps);
    assert(near(surface.hu(u, v), huFD, tol),
      `hu at (${u},${v}): analytic=${surface.hu(u,v)}, FD=${huFD}`);
    assert(near(surface.hv(u, v), hvFD, tol),
      `hv at (${u},${v}): analytic=${surface.hv(u,v)}, FD=${hvFD}`);
  }
  ok('surface.hu, surface.hv match centered finite differences');
}

// (3) lift([u, v]) = [u, v, h(u, v)].
{
  for (const [u, v] of [[0, 0], [1.2, -0.4], [-2, 1.7]]) {
    const p = lift([u, v]);
    assert(vNear(p, [u, v, surface.h(u, v)]),
      `lift(${u},${v}) = ${p}`);
  }
  ok('lift([u,v]) = [u, v, h(u,v)]');
}

// (4) liftTangent(p, [a, b]) = [a, b, a·hu(p) + b·hv(p)] (Jacobian columns).
{
  const p = [0.7, -0.3];
  const t1 = liftTangent(p, [1, 0]);
  assert(vNear(t1, [1, 0, surface.hu(...p)]));
  const t2 = liftTangent(p, [0, 1]);
  assert(vNear(t2, [0, 1, surface.hv(...p)]));
  // Linearity:
  const tg = liftTangent(p, [0.7, -1.3]);
  assert(vNear(tg, [0.7, -1.3,
    0.7 * surface.hu(...p) + (-1.3) * surface.hv(...p)]));
  ok('liftTangent: ∂_uΦ, ∂_vΦ, and linearity in chart components');
}

// (5) liftField for the lec05 default field at a known point.
{
  const lec05Field = {
    Vu: (u, v) => 0.85 + 0.15 * v,
    Vv: (u, _v) => 0.55 * Math.cos(0.7 * u),
  };
  const p = [-2.0, -0.3];
  const Vlift = liftField(lec05Field, ...p);
  const expectedVu = 0.85 + 0.15 * (-0.3);  // 0.805
  const expectedVv = 0.55 * Math.cos(0.7 * -2.0);
  const expectedVz = expectedVu * surface.hu(...p) + expectedVv * surface.hv(...p);
  assert(vNear(Vlift, [expectedVu, expectedVv, expectedVz], 1e-12),
    `liftField at ${p}: ${Vlift} vs expected (${expectedVu}, ${expectedVv}, ${expectedVz})`);
  ok('liftField at (-2.0,-0.3) matches sim_lec05_flow closed form');
}

// (6) liftPath maps a chart-coord polyline to the lifted 3D polyline.
{
  const path = [[0, 0], [1, 0], [1, 1], [0, 1]];
  const lifted = liftPath(path);
  assert.strictEqual(lifted.length, 4);
  for (let i = 0; i < 4; i++) {
    assert(vNear(lifted[i], [...path[i], surface.h(...path[i])]));
  }
  ok('liftPath: lifts every node; length preserved');
}

// (7) Projector: project(0,0,0) = (0, 0, 0) for any view.
{
  const p = makeProjector({ yaw: 0.4, pitch: 0.6 });
  assert(vNear(p(0, 0, 0), [0, 0, 0]));
  ok('Projector: projects origin to origin');
}

// (8) Projector linearity (orthographic): proj(α·v) = α·proj(v).
{
  const p = makeProjector({ yaw: Math.PI * 0.20, pitch: Math.PI * 0.22 });
  const v = [1.3, -2.1, 0.4];
  const a = p(...v);
  const b = p(2 * v[0], 2 * v[1], 2 * v[2]);
  assert(vNear(b, [2*a[0], 2*a[1], 2*a[2]], 1e-12));
  // And additivity: proj(u + v) = proj(u) + proj(v)
  const u = [0.5, 1.2, -0.3];
  const pu = p(...u);
  const pv = p(...v);
  const psum = p(u[0]+v[0], u[1]+v[1], u[2]+v[2]);
  assert(vNear(psum, [pu[0]+pv[0], pu[1]+pv[1], pu[2]+pv[2]], 1e-12));
  ok('Projector linearity: scaling and additivity');
}

// (9) Projector with yaw=0, pitch=0 sends z to the screen-Y axis (depth=0).
//     Specifically pure +z should project to (0, +z, 0): straight up on screen.
{
  const p = makeProjector({ yaw: 0, pitch: 0 });
  // With our convention (yaw rotates around z, then pitch tilts; return [X, Y, depth])
  const pz = p(0, 0, 1);
  assert(near(pz[0], 0));
  assert(near(pz[1], 1));   // +z -> +Y on screen
  // +x stays +X on screen, +y stays in depth direction
  const px_ = p(1, 0, 0);
  assert(near(px_[0], 1));
  assert(near(px_[1], 0));
  ok('Projector yaw=0,pitch=0: x→X, z→Y on screen');
}

// (10) Projector at yaw=π/2 swaps x and y in the world-to-screen mapping.
{
  const p = makeProjector({ yaw: Math.PI / 2, pitch: 0 });
  // x=1 should now project to where y=1 used to (after 90° yaw):
  const px_ = p(1, 0, 0);
  // After yaw=π/2 (rotation around z): x→-y axis in the rotated frame.
  // Using our convention from tangent-basis.html: x1 = x*cy - y*sy; y1 = x*sy + y*cy.
  // So x=1, y=0, yaw=π/2 ⇒ x1=0, y1=1. Then pitch=0: y2=y1, z2=z. Return [x1, z2, y2].
  // Expected: [0, 0, 1].
  assert(vNear(px_, [0, 0, 1], 1e-12), `proj(1,0,0) at yaw=π/2: ${px_}`);
  ok('Projector at yaw=π/2 rotates (x,y) by 90°');
}

console.log(`\nmanifold.mjs: ${n}/10 tests passed`);
