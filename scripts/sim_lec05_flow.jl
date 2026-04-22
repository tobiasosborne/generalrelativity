#!/usr/bin/env julia
# sim_lec05_flow.jl — Vector field, integral curve, and one-parameter flow
# for Lecture 5 (flows on manifolds).
#
# Surface (re-using the lec03/lec04 chart surface):
#     M = { (x,y,z) : z = h(x,y) },  h(x,y) = 0.5·cos(0.9·x) + 0.35·sin(0.6·y)
#
# Vector field in chart coordinates (u,v) = (x,y):
#     V^u(u,v) = 0.85 + 0.15·v
#     V^v(u,v) = 0.55·cos(0.7·u)
# Lifted to M via the parametrisation Φ(u,v) = (u, v, h(u,v)):
#     v|_q = V^u·∂_uΦ + V^v·∂_vΦ
#
# Integral curve C_p(t) = Φ_t(p) is the solution of
#     du/dt = V^u(u,v),  dv/dt = V^v(u,v),  with  C_p(0) = p
#
# Three marked points along the orbit:
#     p,  Φ_t(p)  at  t = t1,  Φ_{t+s}(p)  at  t = t1 + s1.
#
# Run:    julia --project=scripts scripts/sim_lec05_flow.jl
# Output: latex/data/lec05_flow_*.dat

using Printf
using DifferentialEquations
using StaticArrays

const DATADIR = joinpath(@__DIR__, "..", "latex", "data")
mkpath(DATADIR)

# ── Surface (matches sim_lec03_charts.jl) ───────────────────
h(x, y) = 0.5*cos(0.9*x) + 0.35*sin(0.6*y)

# Jacobian columns of Φ : (u,v) ↦ (u,v,h(u,v))
∂uΦ(x, y) = (1.0, 0.0, -0.5*0.9*sin(0.9*x))
∂vΦ(x, y) = (0.0, 1.0,  0.35*0.6*cos(0.6*y))

# ── Chart-coordinate vector field ───────────────────────────
Vu(u, v) = 0.85 + 0.15*v
Vv(u, v) = 0.55*cos(0.7*u)

# Lifted vector at q = (u, v, h(u,v)):  V^u·∂_uΦ + V^v·∂_vΦ
function lifted(u, v)
    a, b = Vu(u, v), Vv(u, v)
    ∂u = ∂uΦ(u, v)
    ∂v = ∂vΦ(u, v)
    return (a*∂u[1] + b*∂v[1],
            a*∂u[2] + b*∂v[2],
            a*∂u[3] + b*∂v[3])
end

# ── Surface mesh (same domain as lec03 charts) ──────────────
const N = 55
const x_range = range(-3.0, 3.0, length=N)
const y_range = range(-3.0, 3.0, length=N)

println("Writing surface mesh $(N)×$(N)...")
open(joinpath(DATADIR, "lec05_flow_surface.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    for x in x_range
        for y in y_range
            @printf(io, "%.6f  %.6f  %.6f\n", x, y, h(x, y))
        end
        println(io)
    end
end

# ── Sparse field arrows on M (5×5 grid, scaled for visibility) ──
const ARROW_GRID = range(-2.2, 2.2, length=5)
const ARROW_SCALE = 0.45

println("Writing field arrows on M...")
open(joinpath(DATADIR, "lec05_flow_field.dat"), "w") do io
    @printf(io, "# x  y  z  vx  vy  vz\n")
    for u in ARROW_GRID
        for v in ARROW_GRID
            vx, vy, vz = lifted(u, v)
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    u, v, h(u, v),
                    ARROW_SCALE*vx, ARROW_SCALE*vy, ARROW_SCALE*vz)
        end
    end
end

# ── ODE for integral curve in chart coords ──────────────────
function flow!(du, st, _, _)
    du[1] = Vu(st[1], st[2])
    du[2] = Vv(st[1], st[2])
end

# Starting point p (chosen so the orbit traverses the bumpy region)
const p_u, p_v = -2.0, -0.3

# Orbit parameters
const t1   = 1.6      # parameter at Φ_t(p)
const s1   = 1.7      # parameter increment to Φ_{t+s}(p)
const tend = 4.4      # integrate slightly past t1 + s1 for visual lead-out

println("Integrating orbit from p=($(p_u), $(p_v)) to t=$(tend)...")
prob = ODEProblem(flow!, [p_u, p_v], (0.0, tend))
sol  = solve(prob, Tsit5(); abstol=1e-10, reltol=1e-10, saveat=0.02)

# Whole orbit lifted to M
open(joinpath(DATADIR, "lec05_flow_orbit_M.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    for st in sol.u
        u, v = st[1], st[2]
        @printf(io, "%.6f  %.6f  %.6f\n", u, v, h(u, v))
    end
end

# Orbit projected to the chart (for an optional 2D inset; not required)
open(joinpath(DATADIR, "lec05_flow_orbit_chart.dat"), "w") do io
    @printf(io, "# u  v\n")
    for st in sol.u
        @printf(io, "%.6f  %.6f\n", st[1], st[2])
    end
end

# Three marked points: p, Φ_t(p), Φ_{t+s}(p)
function pt_at(t)
    st = sol(t)
    return (st[1], st[2], h(st[1], st[2]))
end

let
    p_M       = pt_at(0.0)
    phi_t_M   = pt_at(t1)
    phi_ts_M  = pt_at(t1 + s1)

    open(joinpath(DATADIR, "lec05_flow_points_M.dat"), "w") do io
        @printf(io, "# x  y  z   label_index (0:p, 1:Φ_t(p), 2:Φ_{t+s}(p))\n")
        @printf(io, "%.6f  %.6f  %.6f  0\n", p_M...)
        @printf(io, "%.6f  %.6f  %.6f  1\n", phi_t_M...)
        @printf(io, "%.6f  %.6f  %.6f  2\n", phi_ts_M...)
    end

    # Tangent vector v|_p (the lifted field value at p), scaled
    let s = 0.6
        vx, vy, vz = lifted(p_u, p_v)
        open(joinpath(DATADIR, "lec05_flow_tangent_p.dat"), "w") do io
            @printf(io, "# x  y  z  vx  vy  vz\n")
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    p_M[1], p_M[2], p_M[3], s*vx, s*vy, s*vz)
        end
        @printf("v|_p (lifted) = (%.3f, %.3f, %.3f)\n", vx, vy, vz)
    end

    @printf("p          = (%.3f, %.3f, %.3f)\n", p_M...)
    @printf("Φ_t(p)     = (%.3f, %.3f, %.3f)   t = %.2f\n", phi_t_M..., t1)
    @printf("Φ_{t+s}(p) = (%.3f, %.3f, %.3f)   t+s = %.2f\n", phi_ts_M..., t1+s1)
end

println("Done. All files in $DATADIR")
