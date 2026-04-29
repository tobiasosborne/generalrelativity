#!/usr/bin/env julia
# sim_lec07_lec08.jl — connection, parallel transport, and geodesics on the
# wavy graph surface M (the recurring example manifold from lectures 3–6).
#
# Surface M = { (x,y,z) : z = h(x,y) },  h(x,y) = 0.5·cos(0.9·x) + 0.35·sin(0.6·y).
# Embedding Φ : (u,v) ↦ (u, v, h(u,v)).
# Induced (pulled-back Euclidean) metric in chart-α coords:
#     g_{uu} = 1 + h_u^2,  g_{uv} = h_u h_v,  g_{vv} = 1 + h_v^2
# Levi-Civita Christoffel symbols Γ^σ_{μν} are computed from this metric.
#
# Run:    julia --project=scripts scripts/sim_lec07_lec08.jl
# Output: latex/data/lec07_*.dat and latex/data/lec08_*.dat

using Printf
using LinearAlgebra
using DifferentialEquations

const DATADIR = joinpath(@__DIR__, "..", "latex", "data")
mkpath(DATADIR)

# ── Surface and derivatives ─────────────────────────────────
h(u, v)   = 0.5*cos(0.9*u) + 0.35*sin(0.6*v)
hu(u, v)  = -0.45*sin(0.9*u)
hv(u, v)  =  0.21*cos(0.6*v)
huu(u, v) = -0.405*cos(0.9*u)
huv(u, v) =  0.0
hvv(u, v) = -0.126*sin(0.6*v)

∂uΦ(u, v) = (1.0, 0.0, hu(u,v))
∂vΦ(u, v) = (0.0, 1.0, hv(u,v))

# Lift a chart-coord vector at (u,v) to a 3-vector tangent to M
function lift(p_chart, v_chart)
    u, w = p_chart
    Vu, Vw = v_chart
    ∂u = ∂uΦ(u, w)
    ∂v = ∂vΦ(u, w)
    return (Vu*∂u[1] + Vw*∂v[1],
            Vu*∂u[2] + Vw*∂v[2],
            Vu*∂u[3] + Vw*∂v[3])
end

# ── Induced metric and Christoffels ─────────────────────────
function metric_inv(u, v)
    Hu, Hv = hu(u,v), hv(u,v)
    g_uu, g_uv, g_vv = 1+Hu*Hu, Hu*Hv, 1+Hv*Hv
    det = g_uu*g_vv - g_uv*g_uv
    return [g_vv/det -g_uv/det; -g_uv/det g_uu/det]
end

# dg[μ,ν,λ] = ∂_μ g_{νλ}.  Using g_{νλ} = δ_{νλ} + h_ν h_λ,
#   ∂_μ g_{νλ} = (∂_μ h_ν) h_λ + h_ν (∂_μ h_λ) = H[μ,ν] G[λ] + G[ν] H[μ,λ].
function christoffel(u, v)
    gi = metric_inv(u, v)
    H  = [huu(u,v) huv(u,v); huv(u,v) hvv(u,v)]
    G  = [hu(u,v), hv(u,v)]
    dg = zeros(2,2,2)
    for μ in 1:2, ν in 1:2, λ in 1:2
        dg[μ,ν,λ] = H[μ,ν]*G[λ] + G[ν]*H[μ,λ]
    end
    Γ = zeros(2,2,2)  # Γ[σ,μ,ν]
    for σ in 1:2, μ in 1:2, ν in 1:2
        s = 0.0
        for λ in 1:2
            s += gi[σ,λ] * (dg[μ,ν,λ] + dg[ν,μ,λ] - dg[λ,μ,ν])
        end
        Γ[σ,μ,ν] = 0.5*s
    end
    return Γ
end

# ── Surface mesh (matches lec03 charts) ─────────────────────
const N = 55
const x_range = range(-3.0, 3.0, length=N)
const y_range = range(-3.0, 3.0, length=N)

println("Writing surface mesh ($(N)×$(N))...")
open(joinpath(DATADIR, "lec07_surface.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    for x in x_range
        for y in y_range
            @printf(io, "%.6f  %.6f  %.6f\n", x, y, h(x,y))
        end
        println(io)
    end
end

# ════════════════════════════════════════════════════════════
#  LECTURE 7 — coordinate basis along a curve, two connections
# ════════════════════════════════════════════════════════════

# ── (1) Coordinate-basis vectors at points along a curve ────
# Curve in chart coords:  c(t) = (t, 0.5·sin(0.7·t)),  t ∈ [-1.7, 1.7].
# At each sample point we draw the basis vectors ∂_u Φ, ∂_v Φ tangent to M.
let
    println("Writing chart-basis-along-curve data...")
    c_xy(t) = (t, 0.5*sin(0.7*t))
    Nc      = 200
    t_curve = range(-1.7, 1.7, length=Nc)

    open(joinpath(DATADIR, "lec07_basis_curve.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for t in t_curve
            u, v = c_xy(t)
            @printf(io, "%.6f  %.6f  %.6f\n", u, v, h(u,v))
        end
    end

    sample_t = (-1.4, -0.4, 0.6, 1.5)
    s = 0.55  # vector length scale for visibility

    open(joinpath(DATADIR, "lec07_basis_du.dat"), "w") do io
        @printf(io, "# x  y  z  vx  vy  vz   (∂_u Φ at sample points)\n")
        for t in sample_t
            u, v = c_xy(t)
            ∂u = ∂uΦ(u, v)
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    u, v, h(u,v), s*∂u[1], s*∂u[2], s*∂u[3])
        end
    end
    open(joinpath(DATADIR, "lec07_basis_dv.dat"), "w") do io
        @printf(io, "# x  y  z  vx  vy  vz   (∂_v Φ at sample points)\n")
        for t in sample_t
            u, v = c_xy(t)
            ∂v = ∂vΦ(u, v)
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    u, v, h(u,v), s*∂v[1], s*∂v[2], s*∂v[3])
        end
    end
    open(joinpath(DATADIR, "lec07_basis_points.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for t in sample_t
            u, v = c_xy(t)
            @printf(io, "%.6f  %.6f  %.6f\n", u, v, h(u,v))
        end
    end
    @printf("  basis sample points (chart): ")
    for t in sample_t
        u, v = c_xy(t)
        @printf("(%.2f,%.2f) ", u, v)
    end
    println()
end

# ── (2) Difference of two connections: the C-tensor is algebraic ────
# Compare two connections on M:
#   ∂_a   = chart-α partial derivative (treats chart components as scalars)
#   ∇_a   = Levi-Civita derivative for the induced metric
#
# Choose W to be chart-constant:  W^u ≡ 1,  W^v ≡ 0.
# Then  ∂_a W^b = 0  identically — W "looks parallel" to chart α.
# In direction X = ∂/∂u, however,
#   (∇ − ∂)_X W^σ  =  X^a Γ^σ_{a,c} W^c  =  Γ^σ_{u,u}|_p,
# a purely *algebraic* tensor in W|_p (no derivatives of W needed) —
# this is the C-tensor of Theorem 7.4.
#
# At several "field points" we draw W lifted to M: same chart components,
# but visibly tilted with the surface — so they are not parallel transports
# of one another in 3D.  At the focal point p_diff we draw the Levi-Civita
# correction ∇_X W; ∂_X W = 0 so what we see is *all* C-tensor.
let
    println("Writing two-connections difference data...")
    p_u, p_v = -1.0, 1.5         # focal point (steeper region)
    p_z = h(p_u, p_v)

    Wu_const, Wv_const = 1.0, 0.0
    sample_pts = [(-2.2, 0.7), (-1.6, 1.1), (-1.0, 1.5), (-0.4, 1.7), (0.4, 1.5)]
    s_field = 0.55

    open(joinpath(DATADIR, "lec07_diff_field_points.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for (u, v) in sample_pts
            @printf(io, "%.6f  %.6f  %.6f\n", u, v, h(u,v))
        end
    end
    open(joinpath(DATADIR, "lec07_diff_W_field.dat"), "w") do io
        @printf(io, "# x  y  z  vx  vy  vz   (chart-constant W^u=1, W^v=0 at each pt)\n")
        for (u, v) in sample_pts
            v3 = lift((u, v), (Wu_const, Wv_const))
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    u, v, h(u,v), s_field*v3[1], s_field*v3[2], s_field*v3[3])
        end
    end

    Γ = christoffel(p_u, p_v)
    # X = ∂_u, W = ∂_u (chart-constant).  ∇_X W^σ = Γ^σ_{u,u} W^u = Γ^σ_{u,u}.
    covd_u = Γ[1, 1, 1]*Wu_const + Γ[1, 1, 2]*Wv_const
    covd_v = Γ[2, 1, 1]*Wu_const + Γ[2, 1, 2]*Wv_const
    ∇W_chart_norm = sqrt(covd_u^2 + covd_v^2)

    W_3   = lift((p_u, p_v), (Wu_const, Wv_const))
    ∇W_3  = lift((p_u, p_v), (covd_u,   covd_v))

    s_W = 0.55
    s_∇ = 7.0   # exaggeration factor: shown as "× 7" in the figure caption

    open(joinpath(DATADIR, "lec07_diff_p.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        @printf(io, "%.6f  %.6f  %.6f\n", p_u, p_v, p_z)
    end
    open(joinpath(DATADIR, "lec07_diff_W_at_p.dat"), "w") do io
        @printf(io, "# x  y  z  vx  vy  vz   (W|_p lifted)\n")
        @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                p_u, p_v, p_z, s_W*W_3[1], s_W*W_3[2], s_W*W_3[3])
    end
    open(joinpath(DATADIR, "lec07_diff_covdXW.dat"), "w") do io
        @printf(io, "# x  y  z  vx  vy  vz   (∇_X W = Γ^σ_uu, scaled ×%.0f)\n", s_∇)
        @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                p_u, p_v, p_z, s_∇*∇W_3[1], s_∇*∇W_3[2], s_∇*∇W_3[3])
    end

    @printf("  p_diff         = (%.3f, %.3f, %.3f)\n", p_u, p_v, p_z)
    @printf("  W (chart)      = (%.3f, %.3f)   chart-constant, so ∂_X W = 0\n",
            Wu_const, Wv_const)
    @printf("  ∇_X W (chart)  = (%.3f, %.3f)   = (Γ^u_uu, Γ^v_uu)|_p\n",
            covd_u, covd_v)
    @printf("  |∇_X W| chart  = %.4f   (figure scale ×%.0f)\n",
            ∇W_chart_norm, s_∇)
end

# ════════════════════════════════════════════════════════════
#  LECTURE 8 — parallel transport, naive vs LC, polar, geodesic
# ════════════════════════════════════════════════════════════

# ── (3,4) Parallel transport on M; naive vs Levi-Civita ─────
# Curve in chart coords:  c(t) traces a half-loop sweeping the bumpy region:
#     c(t) = (2.0·cos(0.7·t) − 0.2,  1.8·sin(0.7·t) − 0.5),  t ∈ [0, 4.49].
# Initial vector at p = c(0):  v(0) = (-0.4, 0.85) in chart basis (chosen
# transverse to ċ(0) so that LC and naive transports drift visibly apart).
# LC ODE:    dv^σ/dt = − Γ^σ_{μν}(c(t)) ċ^μ v^ν.
# Naive:     v^σ(t) ≡ v^σ(0)  (chart components held constant).

c_xy(t)    = (2.0*cos(0.7*t) - 0.2, 1.8*sin(0.7*t) - 0.5)
cdot_xy(t) = (-2.0*0.7*sin(0.7*t),   1.8*0.7*cos(0.7*t))

function pt_rhs!(dv, v, _, t)
    u, w = c_xy(t)
    Γ    = christoffel(u, w)
    cu, cw = cdot_xy(t)
    cdot = (cu, cw)
    for σ in 1:2
        s = 0.0
        for μ in 1:2, ν in 1:2
            s += Γ[σ,μ,ν] * cdot[μ] * v[ν]
        end
        dv[σ] = -s
    end
end

let
    println("Integrating parallel-transport ODE on M...")
    v0    = [-0.4, 0.85]
    T_END = π/0.7   # half-loop in chart coords
    tspan = (0.0, T_END)
    prob  = ODEProblem(pt_rhs!, v0, tspan)
    sol   = solve(prob, Tsit5(); abstol=1e-10, reltol=1e-10, saveat=0.005)

    # Curve on M
    Nc      = 280
    t_curve = range(0.0, T_END, length=Nc)
    open(joinpath(DATADIR, "lec08_pt_curve_M.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for t in t_curve
            u, v = c_xy(t)
            @printf(io, "%.6f  %.6f  %.6f\n", u, v, h(u,v))
        end
    end

    sample_t = range(0.0, T_END, length=6)
    s = 0.55  # arrow length scale

    open(joinpath(DATADIR, "lec08_pt_vectors_lc.dat"), "w") do io
        @printf(io, "# x  y  z  vx  vy  vz\n")
        for t in sample_t
            u, w = c_xy(t)
            v_chart = sol(t)
            v3 = lift((u, w), (v_chart[1], v_chart[2]))
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    u, w, h(u,w), s*v3[1], s*v3[2], s*v3[3])
        end
    end
    open(joinpath(DATADIR, "lec08_pt_vectors_naive.dat"), "w") do io
        @printf(io, "# x  y  z  vx  vy  vz   (chart components held constant)\n")
        for t in sample_t
            u, w = c_xy(t)
            v3 = lift((u, w), (v0[1], v0[2]))
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    u, w, h(u,w), s*v3[1], s*v3[2], s*v3[3])
        end
    end
    open(joinpath(DATADIR, "lec08_pt_endpoints.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for t in (0.0, T_END)
            u, w = c_xy(t)
            @printf(io, "%.6f  %.6f  %.6f\n", u, w, h(u,w))
        end
    end

    @printf("  v(0) (chart) = (%.3f, %.3f)\n", v0...)
    @printf("  v(T_END) (chart) = (%.3f, %.3f)   (Levi-Civita)\n",
            sol(T_END)[1], sol(T_END)[2])
end

# ── (5) Polar coords: radial parallel transport in R² ───────
# Cartesian-flat metric in polar (r,φ).  Parallel transport along the radial
# line φ = φ_0 of a Cartesian-constant vector  v = (1, 0):
#     v^r(r)  = cos(φ_0)            (constant)        ⇒ dv^r/dr = 0
#     v^φ(r)  = − sin(φ_0)/r        (i.e. v^φ = A/r,  A = − sin φ_0)
let
    println("Writing polar-coord radial-transport data...")
    φ0    = π/6
    radii = (0.5, 1.0, 1.5, 2.0, 2.5)

    open(joinpath(DATADIR, "lec08_polar_points.dat"), "w") do io
        @printf(io, "# x  y\n")
        for r in radii
            @printf(io, "%.6f  %.6f\n", r*cos(φ0), r*sin(φ0))
        end
    end
    s = 0.45
    open(joinpath(DATADIR, "lec08_polar_vectors.dat"), "w") do io
        @printf(io, "# x  y  vx  vy   (Cartesian-constant vector at each radius)\n")
        for r in radii
            @printf(io, "%.6f  %.6f  %.6f  %.6f\n",
                    r*cos(φ0), r*sin(φ0), s*1.0, s*0.0)
        end
    end
    open(joinpath(DATADIR, "lec08_polar_ray.dat"), "w") do io
        @printf(io, "# x  y\n")
        @printf(io, "0.000000  0.000000\n")
        @printf(io, "%.6f  %.6f\n", 3.0*cos(φ0), 3.0*sin(φ0))
    end
    # Concentric circles at r = 0.5, 1.0, …, 3.0  (one circle per dataset block)
    open(joinpath(DATADIR, "lec08_polar_circles.dat"), "w") do io
        @printf(io, "# x  y\n")
        for r in (0.5, 1.0, 1.5, 2.0, 2.5, 3.0)
            for θ in range(0, 2π, length=120)
                @printf(io, "%.6f  %.6f\n", r*cos(θ), r*sin(θ))
            end
            println(io)
        end
    end
    # Side panel: v^φ(r) = −sin(φ_0)/r
    open(joinpath(DATADIR, "lec08_polar_vphi.dat"), "w") do io
        @printf(io, "# r  v_phi\n")
        for r in range(0.3, 3.0, length=160)
            @printf(io, "%.6f  %.6f\n", r, -sin(φ0)/r)
        end
    end
    # And v^r = cos(φ_0) (a constant) — for the same panel
    open(joinpath(DATADIR, "lec08_polar_vr.dat"), "w") do io
        @printf(io, "# r  v_r\n")
        for r in range(0.3, 3.0, length=2)
            @printf(io, "%.6f  %.6f\n", r, cos(φ0))
        end
    end

    @printf("  φ_0 = π/6;  v^r ≡ cos(φ_0) = %.4f;  v^φ = A/r,  A = −sin(φ_0) = %.4f\n",
            cos(φ0), -sin(φ0))
end

# ── (6) Geodesic on M ───────────────────────────────────────
# Initial p = (-2.0, -1.5),  initial T = (0.7, 0.4) in chart coords.
# Geodesic ODE in chart coords:  ẍ^σ + Γ^σ_{μν}(x) ẋ^μ ẋ^ν = 0.
function geo_rhs!(du, st, _, _)
    x  = (st[1], st[2])
    ẋ  = (st[3], st[4])
    Γ  = christoffel(x[1], x[2])
    du[1] = ẋ[1]
    du[2] = ẋ[2]
    for σ in 1:2
        s = 0.0
        for μ in 1:2, ν in 1:2
            s += Γ[σ,μ,ν] * ẋ[μ] * ẋ[ν]
        end
        du[2+σ] = -s
    end
end

let
    println("Integrating geodesic ODE on M...")
    p0    = [-2.0, -1.5]
    T0    = [0.7,  0.4]
    tspan = (0.0, 5.0)
    st0   = [p0..., T0...]
    prob  = ODEProblem(geo_rhs!, st0, tspan)
    sol   = solve(prob, Tsit5(); abstol=1e-10, reltol=1e-10, saveat=0.005)

    # Whole geodesic on M (clip to surface domain)
    open(joinpath(DATADIR, "lec08_geodesic_M.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for st in sol.u
            u, v = st[1], st[2]
            (-3.0 ≤ u ≤ 3.0 && -3.0 ≤ v ≤ 3.0) || continue
            @printf(io, "%.6f  %.6f  %.6f\n", u, v, h(u,v))
        end
    end

    sample_t = (0.0, 1.0, 2.0, 3.0, 4.0)
    s = 0.55
    open(joinpath(DATADIR, "lec08_geodesic_tangents.dat"), "w") do io
        @printf(io, "# x  y  z  tx  ty  tz\n")
        for t in sample_t
            st = sol(t)
            u, v = st[1], st[2]
            (-3.0 ≤ u ≤ 3.0 && -3.0 ≤ v ≤ 3.0) || continue
            T_chart = (st[3], st[4])
            T3 = lift((u, v), T_chart)
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    u, v, h(u,v), s*T3[1], s*T3[2], s*T3[3])
        end
    end
    open(joinpath(DATADIR, "lec08_geodesic_endpoints.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for t in (0.0, 5.0)
            st = sol(t)
            u, v = st[1], st[2]
            (-3.0 ≤ u ≤ 3.0 && -3.0 ≤ v ≤ 3.0) || continue
            @printf(io, "%.6f  %.6f  %.6f\n", u, v, h(u,v))
        end
    end

    final = sol(5.0)
    @printf("  geodesic from p=(%.2f,%.2f) with T=(%.2f,%.2f)\n", p0..., T0...)
    @printf("  end (t=5):  x=(%.3f,%.3f)  T=(%.3f,%.3f)\n",
            final[1], final[2], final[3], final[4])
end

println("\nDone. All files in $DATADIR")
