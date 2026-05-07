#!/usr/bin/env julia
# sim_lec09_lec10.jl — Path-dependent parallel transport on S² (lec09);
# curve-with-tangent, curve-and-chart, and rectangular-loop holonomy on the
# wavy surface M (lec10).
#
# Surfaces:
#   • Lec09:  S² (unit sphere).
#   • Lec10:  M = { (x,y,z) : z = h(x,y) },  h = 0.5·cos(0.9x) + 0.35·sin(0.6y).
#
# Run:    julia --project=scripts scripts/sim_lec09_lec10.jl
# Output: latex/data/lec09_*.dat, latex/data/lec10_*.dat

using Printf
using LinearAlgebra
using DifferentialEquations

const DATADIR = joinpath(@__DIR__, "..", "latex", "data")
mkpath(DATADIR)

# ════════════════════════════════════════════════════════════
#  LECTURE 9 — path-dependent parallel transport on S²
# ════════════════════════════════════════════════════════════
#
# Initial tangent vector  w₀ = (1, 0, 0)  at the north pole  p = (0, 0, 1).
# Two paths to the common endpoint  q = (1, 0, 0):
#   γ₁ : meridian φ = 0                    p → q
#   γ₂ : meridian φ = π/2  then  equator   p → (0,1,0) → q
# Parallel transport on the unit sphere (in the embedding ℝ³) satisfies
#     dw/ds = −(w · γ̇) · γ(s),
# i.e.\ the only allowed acceleration is normal to the sphere.  Analytic
# answers (verified by the integration below):
#     w_{γ₁}(q) = (0, 0, −1)        (south-pointing tangent at q)
#     w_{γ₂}(q) = (0, −1, 0)        (along the equator at q)
# These differ by π/2 — the area of the spherical triangle equals the
# holonomy angle on the unit sphere.

# Path parametrisations on S² (each by arc length s ∈ [0, π/2])
γ1(s)  = (sin(s), 0.0, cos(s))        # meridian φ = 0
γ̇1(s) = (cos(s), 0.0, -sin(s))

γ2a(s)  = (0.0, sin(s), cos(s))       # meridian φ = π/2
γ̇2a(s) = (0.0, cos(s), -sin(s))

γ2b(s)  = (sin(s), cos(s), 0.0)       # equator from (0,1,0) toward (1,0,0)
γ̇2b(s) = (cos(s), -sin(s), 0.0)

function pt_sphere_rhs!(γ, γ̇)
    return function(dw, w, _, s)
        γs  = γ(s); γ̇s = γ̇(s)
        proj = w[1]*γ̇s[1] + w[2]*γ̇s[2] + w[3]*γ̇s[3]
        dw[1] = -proj*γs[1]; dw[2] = -proj*γs[2]; dw[3] = -proj*γs[3]
    end
end

const W0   = [1.0, 0.0, 0.0]
const SEND = π/2

println("Lecture 9: integrating parallel transport on S²...")

prob1  = ODEProblem(pt_sphere_rhs!(γ1, γ̇1),  copy(W0), (0.0, SEND))
sol1   = solve(prob1,  Tsit5(); abstol=1e-11, reltol=1e-11, saveat=0.005)

prob2a = ODEProblem(pt_sphere_rhs!(γ2a, γ̇2a), copy(W0), (0.0, SEND))
sol2a  = solve(prob2a, Tsit5(); abstol=1e-11, reltol=1e-11, saveat=0.005)

prob2b = ODEProblem(pt_sphere_rhs!(γ2b, γ̇2b), copy(sol2a.u[end]), (0.0, SEND))
sol2b  = solve(prob2b, Tsit5(); abstol=1e-11, reltol=1e-11, saveat=0.005)

W_path1_at_q = sol1.u[end]
W_path2_at_q = sol2b.u[end]

@printf("  w₀         = (%.4f, %.4f, %.4f)   |w| = %.6f\n",
        W0..., norm(W0))
@printf("  w_{γ₁}(q)  = (%.4f, %.4f, %.4f)   |w| = %.6f\n",
        W_path1_at_q..., norm(W_path1_at_q))
@printf("  w_{γ₂}(q)  = (%.4f, %.4f, %.4f)   |w| = %.6f\n",
        W_path2_at_q..., norm(W_path2_at_q))
@printf("  ∡(w₁, w₂)  = %.4f rad   (expected π/2 = %.4f)\n",
        acos(clamp(dot(W_path1_at_q, W_path2_at_q), -1.0, 1.0)), π/2)

# ── Sphere mesh ────────────────────────────────────────────
let
    Nθ, Nφ = 50, 90
    open(joinpath(DATADIR, "lec09_sphere.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for θ in range(0.001, π-0.001, length=Nθ)
            for φ in range(-π, π, length=Nφ)
                @printf(io, "%.6f  %.6f  %.6f\n",
                        sin(θ)*cos(φ), sin(θ)*sin(φ), cos(θ))
            end
            println(io)
        end
    end
end

# ── Path curves ───────────────────────────────────────────
let
    Nc = 220
    open(joinpath(DATADIR, "lec09_path1_curve.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for s in range(0.0, SEND, length=Nc)
            x, y, z = γ1(s)
            @printf(io, "%.6f  %.6f  %.6f\n", x, y, z)
        end
    end

    open(joinpath(DATADIR, "lec09_path2_curve.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for s in range(0.0, SEND, length=Nc)
            x, y, z = γ2a(s)
            @printf(io, "%.6f  %.6f  %.6f\n", x, y, z)
        end
        for s in range(0.0, SEND, length=Nc)
            x, y, z = γ2b(s)
            @printf(io, "%.6f  %.6f  %.6f\n", x, y, z)
        end
    end
end

# ── Sample transported vectors along each path ────────────
let scale = 0.30
    s1_samples = range(0.18, SEND-0.05, length=4)
    open(joinpath(DATADIR, "lec09_path1_vectors.dat"), "w") do io
        @printf(io, "# x  y  z  vx  vy  vz\n")
        for s in s1_samples
            γs = γ1(s); w = sol1(s)
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    γs..., scale*w[1], scale*w[2], scale*w[3])
        end
    end

    open(joinpath(DATADIR, "lec09_path2_vectors.dat"), "w") do io
        @printf(io, "# x  y  z  vx  vy  vz\n")
        for s in range(0.20, SEND-0.05, length=3)
            γs = γ2a(s); w = sol2a(s)
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    γs..., scale*w[1], scale*w[2], scale*w[3])
        end
        for s in range(0.10, SEND-0.10, length=3)
            γs = γ2b(s); w = sol2b(s)
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    γs..., scale*w[1], scale*w[2], scale*w[3])
        end
    end
end

# ── Initial vector at p, two final vectors at q ───────────
let scale_init = 0.30, scale_q = 0.45
    open(joinpath(DATADIR, "lec09_v_initial.dat"), "w") do io
        @printf(io, "# x  y  z  vx  vy  vz   (w₀ at p = north pole)\n")
        @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                0.0, 0.0, 1.0,
                scale_init*W0[1], scale_init*W0[2], scale_init*W0[3])
    end
    open(joinpath(DATADIR, "lec09_v_path1_at_q.dat"), "w") do io
        @printf(io, "# x  y  z  vx  vy  vz   (w_{γ₁} at q)\n")
        @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                1.0, 0.0, 0.0,
                scale_q*W_path1_at_q[1], scale_q*W_path1_at_q[2], scale_q*W_path1_at_q[3])
    end
    open(joinpath(DATADIR, "lec09_v_path2_at_q.dat"), "w") do io
        @printf(io, "# x  y  z  vx  vy  vz   (w_{γ₂} at q)\n")
        @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                1.0, 0.0, 0.0,
                scale_q*W_path2_at_q[1], scale_q*W_path2_at_q[2], scale_q*W_path2_at_q[3])
    end
end

# ── Marker points: p, q, and the path-2 corner (0,1,0) ────
open(joinpath(DATADIR, "lec09_marker_points.dat"), "w") do io
    @printf(io, "# x  y  z   (p, q, then path-2 corner)\n")
    @printf(io, "%.6f  %.6f  %.6f\n", 0.0, 0.0, 1.0)   # p
    @printf(io, "%.6f  %.6f  %.6f\n", 1.0, 0.0, 0.0)   # q
    @printf(io, "%.6f  %.6f  %.6f\n", 0.0, 1.0, 0.0)   # path-2 corner
end

# ════════════════════════════════════════════════════════════
#  LECTURE 10 — wavy surface M, curve C, chart image, loop holonomy
# ════════════════════════════════════════════════════════════

# ── Surface and helpers (same as lec07/lec08) ─────────────
h(u, v)   = 0.5*cos(0.9*u) + 0.35*sin(0.6*v)
hu(u, v)  = -0.45*sin(0.9*u)
hv(u, v)  =  0.21*cos(0.6*v)
huu(u, v) = -0.405*cos(0.9*u)
huv(u, v) =  0.0
hvv(u, v) = -0.126*sin(0.6*v)

∂uΦ(u, v) = (1.0, 0.0, hu(u,v))
∂vΦ(u, v) = (0.0, 1.0, hv(u,v))

function lift(p_chart, v_chart)
    u, w = p_chart
    Vu, Vw = v_chart
    ∂u = ∂uΦ(u, w); ∂v = ∂vΦ(u, w)
    return (Vu*∂u[1] + Vw*∂v[1],
            Vu*∂u[2] + Vw*∂v[2],
            Vu*∂u[3] + Vw*∂v[3])
end

function metric_inv(u, v)
    Hu, Hv = hu(u,v), hv(u,v)
    g_uu, g_uv, g_vv = 1+Hu*Hu, Hu*Hv, 1+Hv*Hv
    det = g_uu*g_vv - g_uv*g_uv
    return [g_vv/det -g_uv/det; -g_uv/det g_uu/det]
end

function christoffel(u, v)
    gi = metric_inv(u, v)
    H  = [huu(u,v) huv(u,v); huv(u,v) hvv(u,v)]
    G  = [hu(u,v), hv(u,v)]
    dg = zeros(2,2,2)
    for μ in 1:2, ν in 1:2, λ in 1:2
        dg[μ,ν,λ] = H[μ,ν]*G[λ] + G[ν]*H[μ,λ]
    end
    Γ = zeros(2,2,2)
    for σ in 1:2, μ in 1:2, ν in 1:2
        s = 0.0
        for λ in 1:2
            s += gi[σ,λ] * (dg[μ,ν,λ] + dg[ν,μ,λ] - dg[λ,μ,ν])
        end
        Γ[σ,μ,ν] = 0.5*s
    end
    return Γ
end

function metric_tensor(u, v)
    Hu, Hv = hu(u,v), hv(u,v)
    return [1+Hu*Hu  Hu*Hv;
            Hu*Hv   1+Hv*Hv]
end

# ── (1, 2) Curve C from p to q on M; chart image ──────────
# Curve in chart coords: c(t) = (-2 + 4t,  -1 + 1.6·sin(2.5·t)),  t ∈ [0, 1].
# p = c(0) = (-2, -1),  q = c(1) ≈ (2, -0.04).
# Tangent T^a sampled at t = 0.45.
let
    c_xy(t)    = (-2.0 + 4.0*t,  -1.0 + 1.6*sin(2.5*t))
    cdot_xy(t) = ( 4.0,            1.6*2.5*cos(2.5*t))
    Nc = 220
    t_curve = range(0.0, 1.0, length=Nc)

    open(joinpath(DATADIR, "lec10_curve_M.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for t in t_curve
            u, v = c_xy(t)
            @printf(io, "%.6f  %.6f  %.6f\n", u, v, h(u,v))
        end
    end
    open(joinpath(DATADIR, "lec10_curve_chart.dat"), "w") do io
        @printf(io, "# u  v\n")
        for t in t_curve
            u, v = c_xy(t)
            @printf(io, "%.6f  %.6f\n", u, v)
        end
    end

    open(joinpath(DATADIR, "lec10_curve_endpoints_M.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for t in (0.0, 1.0)
            u, v = c_xy(t)
            @printf(io, "%.6f  %.6f  %.6f\n", u, v, h(u,v))
        end
    end
    open(joinpath(DATADIR, "lec10_curve_endpoints_chart.dat"), "w") do io
        @printf(io, "# u  v\n")
        for t in (0.0, 1.0)
            u, v = c_xy(t)
            @printf(io, "%.6f  %.6f\n", u, v)
        end
    end

    let t = 0.45, scale = 0.28
        u, v = c_xy(t)
        T3   = lift((u, v), cdot_xy(t))
        open(joinpath(DATADIR, "lec10_curve_tangent.dat"), "w") do io
            @printf(io, "# x  y  z  Tx  Ty  Tz\n")
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    u, v, h(u,v), scale*T3[1], scale*T3[2], scale*T3[3])
        end
        open(joinpath(DATADIR, "lec10_curve_sample_M.dat"), "w") do io
            @printf(io, "# x  y  z\n")
            @printf(io, "%.6f  %.6f  %.6f\n", u, v, h(u,v))
        end
        open(joinpath(DATADIR, "lec10_curve_sample_chart.dat"), "w") do io
            @printf(io, "# u  v\n")
            @printf(io, "%.6f  %.6f\n", u, v)
        end
        @printf("Lecture 10 curve: T^a sampled at (u,v)=(%.3f,%.3f);  T_3D = (%.3f,%.3f,%.3f)\n",
                u, v, T3...)
    end
end

# ── (3) Rectangular loop with parallel transport on M ─────
# Loop in chart coords sits in the bumpy region.  The four legs are straight
# lines in (u,v) coords; parallel transport is integrated leg-by-leg with
# continuity of v at the corners.  The discrepancy
#     δv  =  v_final − v_initial
# is purely second order in (Δs · Δt); we exaggerate δv visually for
# legibility, in the same spirit as the C-tensor figure of lec07.

function pt_chart_rhs!(dv, v, params, s)
    cfun, cdotfun = params
    u, w   = cfun(s)
    Γ      = christoffel(u, w)
    cu, cw = cdotfun(s)
    cdot   = (cu, cw)
    for σ in 1:2
        sm = 0.0
        for μ in 1:2, ν in 1:2
            sm += Γ[σ,μ,ν] * cdot[μ] * v[ν]
        end
        dv[σ] = -sm
    end
end

let
    A = (-1.40,  0.40)
    B = ( 0.20,  0.40)
    C = ( 0.20,  1.90)
    D = (-1.40,  1.90)
    Δs = B[1] - A[1]
    Δt = D[2] - A[2]

    leg(P, Q) = (s -> (P[1] + s*(Q[1]-P[1]),  P[2] + s*(Q[2]-P[2])),
                 s -> (Q[1]-P[1],             Q[2]-P[2]))

    legs = [leg(A,B), leg(B,C), leg(C,D), leg(D,A)]

    v0_chart = [1.0, 0.0]
    v        = copy(v0_chart)
    for (cfun, cdotfun) in legs
        prob = ODEProblem(pt_chart_rhs!, v, (0.0, 1.0), (cfun, cdotfun))
        sol  = solve(prob, Tsit5(); abstol=1e-12, reltol=1e-12)
        v    = copy(sol.u[end])
    end
    v_final_chart = v
    δv_chart      = v_final_chart .- v0_chart

    # Sanity: |v|² (under metric at A) should be preserved by Levi-Civita
    g_A      = metric_tensor(A...)
    norm0_sq = v0_chart'      * g_A * v0_chart
    normF_sq = v_final_chart' * g_A * v_final_chart
    @printf("Lecture 10 loop:  Δs·Δt = %.4f\n", abs(Δs*Δt))
    @printf("  v₀     (chart) = (%.5f, %.5f)\n", v0_chart...)
    @printf("  v_final(chart) = (%.5f, %.5f)\n", v_final_chart...)
    @printf("  δv     (chart) = (%.5f, %.5f)   |δv| ≈ %.5f\n",
            δv_chart..., norm(δv_chart))
    @printf("  metric norm preserved: |v₀|² = %.6f,  |v_f|² = %.6f  (Δ = %.2e)\n",
            norm0_sq, normF_sq, abs(normF_sq - norm0_sq))

    # Lifted loop on M (4 legs concatenated into one polyline)
    open(joinpath(DATADIR, "lec10_loop_M.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for (cfun, _) in legs
            for s in range(0.0, 1.0, length=80)
                u, w = cfun(s)
                @printf(io, "%.6f  %.6f  %.6f\n", u, w, h(u,w))
            end
        end
    end

    # Lifted corner points (with explicit labels in the figure)
    open(joinpath(DATADIR, "lec10_loop_corners_M.dat"), "w") do io
        @printf(io, "# x  y  z   (A, B, C, D)\n")
        for P in (A, B, C, D)
            @printf(io, "%.6f  %.6f  %.6f\n", P[1], P[2], h(P[1], P[2]))
        end
    end

    # Initial vector v₀ at A (lifted)
    let scale = 0.45
        v3 = lift(A, v0_chart)
        open(joinpath(DATADIR, "lec10_loop_v_initial.dat"), "w") do io
            @printf(io, "# x  y  z  vx  vy  vz   (v₀ at A)\n")
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    A[1], A[2], h(A...),
                    scale*v3[1], scale*v3[2], scale*v3[3])
        end
    end

    # δv at A (lifted, exaggerated by EXAG so the discrepancy is visible
    # alongside v₀; |δv|/|v₀| ≈ 0.057 in chart coords for this loop).
    let EXAG = 14.0, scale = 0.45
        δv3 = lift(A, δv_chart)
        open(joinpath(DATADIR, "lec10_loop_dv.dat"), "w") do io
            @printf(io, "# x  y  z  δvx  δvy  δvz   (δv at A, scaled ×%.0f)\n", EXAG)
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    A[1], A[2], h(A...),
                    scale*EXAG*δv3[1], scale*EXAG*δv3[2], scale*EXAG*δv3[3])
        end
    end
end

println("\nDone. All files in $DATADIR")
