#!/usr/bin/env julia
# sim_lec03.jl — Geodesics and parallel transport on a triaxial ellipsoid
#
# Ellipsoid:  x²/a² + y²/b² + z²/c² = 1,  parametrized by (θ,φ)
# Computes:   induced metric, Christoffel symbols, geodesic ODE,
#             parallel transport ODE
# Outputs:    ellipsoid mesh + geodesics + tangent vectors + parallel transport
#
# Run:  julia --project=. scripts/sim_lec03.jl
# Output: latex/data/lec03_*.dat

using DifferentialEquations
using StaticArrays
using LinearAlgebra
using Printf

const DATADIR = joinpath(@__DIR__, "..", "latex", "data")
mkpath(DATADIR)

# ── Ellipsoid parameters ────────────────────────────────────
const a, b, c = 1.5, 1.0, 0.7

# ── Embedding  (θ,φ) → ℝ³ ──────────────────────────────────
function embedding(θ, φ)
    sθ, cθ = sincos(θ)
    sφ, cφ = sincos(φ)
    return SVector(a*sθ*cφ, b*sθ*sφ, c*cθ)
end

# Jacobian: J[i,j] = ∂(x,y,z)_i / ∂(θ,φ)_j
function jacobian(θ, φ)
    sθ, cθ = sincos(θ)
    sφ, cφ = sincos(φ)
    return SMatrix{3,2}(
        a*cθ*cφ, b*cθ*sφ, -c*sθ,    # ∂/∂θ column
        -a*sθ*sφ, b*sθ*cφ, 0.0       # ∂/∂φ column
    )
end

# ── Induced metric g_ij = J^T J ─────────────────────────────
function metric(θ, φ)
    J = jacobian(θ, φ)
    return J' * J  # 2×2 SMatrix
end

# ── Metric derivatives (analytic) ───────────────────────────
function dmetric(θ, φ)
    sθ, cθ = sincos(θ)
    sφ, cφ = sincos(φ)
    s2θ = 2sθ * cθ   # sin(2θ)
    c2θ = cθ^2 - sθ^2  # cos(2θ)
    s2φ = 2sφ * cφ   # sin(2φ)
    c2φ = cφ^2 - sφ^2  # cos(2φ)

    # g_θθ = a²cos²θ·cos²φ + b²cos²θ·sin²φ + c²sin²θ
    g11 = a^2*cθ^2*cφ^2 + b^2*cθ^2*sφ^2 + c^2*sθ^2

    # ∂g_θθ/∂θ
    dg11_dθ = -a^2*s2θ*cφ^2 - b^2*s2θ*sφ^2 + c^2*s2θ
    # ∂g_θθ/∂φ
    dg11_dφ = a^2*cθ^2*(-s2φ) + b^2*cθ^2*s2φ

    # g_θφ = (b²-a²)·sinθ·cosθ·sinφ·cosφ
    g12 = (b^2 - a^2) * sθ * cθ * sφ * cφ

    # ∂g_θφ/∂θ
    dg12_dθ = (b^2 - a^2) * c2θ * sφ * cφ
    # ∂g_θφ/∂φ
    dg12_dφ = (b^2 - a^2) * sθ * cθ * c2φ

    # g_φφ = a²sin²θ·sin²φ + b²sin²θ·cos²φ
    g22 = a^2*sθ^2*sφ^2 + b^2*sθ^2*cφ^2

    # ∂g_φφ/∂θ
    dg22_dθ = a^2*s2θ*sφ^2 + b^2*s2θ*cφ^2
    # ∂g_φφ/∂φ
    dg22_dφ = a^2*sθ^2*s2φ - b^2*sθ^2*s2φ

    dgdθ = SMatrix{2,2}(dg11_dθ, dg12_dθ, dg12_dθ, dg22_dθ)
    dgdφ = SMatrix{2,2}(dg11_dφ, dg12_dφ, dg12_dφ, dg22_dφ)
    return dgdθ, dgdφ
end

# ── Christoffel symbols ─────────────────────────────────────
function christoffel(θ, φ)
    g = metric(θ, φ)
    ginv = inv(g)
    dgdθ, dgdφ = dmetric(θ, φ)
    dg = (dgdθ, dgdφ)  # dg[k] = ∂g/∂coord_k

    G = zeros(2, 2, 2)  # G[λ, μ, ν]
    for λ in 1:2, μ in 1:2, ν in 1:2
        s = 0.0
        for σ in 1:2
            s += ginv[λ, σ] * (dg[ν][σ, μ] + dg[μ][σ, ν] - dg[σ][μ, ν])
        end
        G[λ, μ, ν] = 0.5 * s
    end
    return G
end

# ── Verification ────────────────────────────────────────────
function christoffel_numerical(θ, φ; ε=1e-6)
    g = metric(θ, φ)
    ginv = inv(g)
    gθp = metric(θ+ε, φ); gθm = metric(θ-ε, φ)
    gφp = metric(θ, φ+ε); gφm = metric(θ, φ-ε)
    dgdθ_num = (gθp - gθm) / (2ε)
    dgdφ_num = (gφp - gφm) / (2ε)
    dg = (dgdθ_num, dgdφ_num)

    G = zeros(2, 2, 2)
    for λ in 1:2, μ in 1:2, ν in 1:2
        s = 0.0
        for σ in 1:2
            s += ginv[λ, σ] * (dg[ν][σ, μ] + dg[μ][σ, ν] - dg[σ][μ, ν])
        end
        G[λ, μ, ν] = 0.5 * s
    end
    return G
end

let
    θ0, φ0 = 1.2, 0.8
    Ga = christoffel(θ0, φ0)
    Gn = christoffel_numerical(θ0, φ0)
    err = maximum(abs.(Ga .- Gn))
    @printf("Christoffel verification at (θ=%.1f, φ=%.1f): max error = %.2e\n",
            θ0, φ0, err)
    @assert err < 1e-4 "Christoffel symbol mismatch!"
end

# ── Geodesic + parallel transport ODE ───────────────────────
# State: u = [θ, φ, vθ, vφ, wθ, wφ]
# where v = geodesic tangent, w = parallel-transported vector
function geodesic_transport!(du, u, p, s)
    θ, φ, vθ, vφ, wθ, wφ = u
    G = christoffel(θ, φ)

    du[1] = vθ
    du[2] = vφ
    # Geodesic equation
    du[3] = -(G[1,1,1]*vθ^2 + 2G[1,1,2]*vθ*vφ + G[1,2,2]*vφ^2)
    du[4] = -(G[2,1,1]*vθ^2 + 2G[2,1,2]*vθ*vφ + G[2,2,2]*vφ^2)
    # Parallel transport: dw^a/ds = -Γ^a_{bc} v^b w^c
    du[5] = -(G[1,1,1]*vθ*wθ + G[1,1,2]*(vθ*wφ + vφ*wθ) + G[1,2,2]*vφ*wφ)
    du[6] = -(G[2,1,1]*vθ*wθ + G[2,1,2]*(vθ*wφ + vφ*wθ) + G[2,2,2]*vφ*wφ)
end

# ── Ellipsoid mesh ──────────────────────────────────────────
const Nm = 60
const mesh_θ = range(0.05, π-0.05, length=Nm)
const mesh_φ = range(-π, π, length=Nm)

println("Writing ellipsoid mesh $(Nm)×$(Nm)...")
open(joinpath(DATADIR, "lec03_ellipsoid.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    for θ in mesh_θ
        for φ in mesh_φ
            p = embedding(θ, φ)
            @printf(io, "%.6f  %.6f  %.6f\n", p[1], p[2], p[3])
        end
        println(io)
    end
end
println("  Wrote lec03_ellipsoid.dat")

# ── Geodesics ───────────────────────────────────────────────
# Initial conditions: (θ₀, φ₀, vθ₀, vφ₀) + initial w perpendicular to v
initial_conditions = [
    (π/3,  0.0,   0.3,  1.0),   # near equator, mostly azimuthal
    (π/4,  π/2,   0.8,  0.5),   # mid-latitude, mixed direction
    (π/2,  -π/3,  0.1,  1.0),   # equatorial, strong φ
    (π/6,  π,    -0.5,  0.8),   # high latitude
]

for (i, (θ0, φ0, vθ0, vφ0)) in enumerate(initial_conditions)
    # Normalize velocity to unit speed
    g = metric(θ0, φ0)
    speed² = g[1,1]*vθ0^2 + 2g[1,2]*vθ0*vφ0 + g[2,2]*vφ0^2
    vθ0 /= sqrt(speed²)
    vφ0 /= sqrt(speed²)

    # Initial parallel-transport vector: perpendicular to v in the metric
    # g(v, w) = 0  →  g11·vθ·wθ + g12·(vθ·wφ + vφ·wθ) + g22·vφ·wφ = 0
    # Choose wθ = -g12*vθ - g22*vφ, wφ = g11*vθ + g12*vφ (then g(v,w)=0 if g is sym)
    # Actually: g(v,w) = (g11·vθ + g12·vφ)·wθ + (g12·vθ + g22·vφ)·wφ
    # Set wθ = -(g12·vθ + g22·vφ), wφ = g11·vθ + g12·vφ → g(v,w) = 0 ✓
    wθ0 = -(g[1,2]*vθ0 + g[2,2]*vφ0)
    wφ0 =  g[1,1]*vθ0 + g[1,2]*vφ0
    # Normalize w to have the same metric norm as v (i.e., 1)
    wnorm² = g[1,1]*wθ0^2 + 2g[1,2]*wθ0*wφ0 + g[2,2]*wφ0^2
    wθ0 /= sqrt(wnorm²)
    wφ0 /= sqrt(wnorm²)

    u0 = [θ0, φ0, vθ0, vφ0, wθ0, wφ0]
    sspan = (0.0, 8.0)

    # Stop near poles
    function pole_check(u, t, integrator)
        return u[1] < 0.05 || u[1] > π - 0.05
    end
    cb = DiscreteCallback(pole_check, terminate!)

    prob = ODEProblem(geodesic_transport!, u0, sspan)
    sol = solve(prob, Tsit5(); abstol=1e-10, reltol=1e-10,
                saveat=0.02, callback=cb)

    # Write geodesic curve (x, y, z)
    open(joinpath(DATADIR, "lec03_geodesic_$i.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for u in sol.u
            p = embedding(u[1], u[2])
            @printf(io, "%.6f  %.6f  %.6f\n", p[1], p[2], p[3])
        end
    end

    # Write tangent vectors at sampled points (every 20th point)
    open(joinpath(DATADIR, "lec03_tangent_$i.dat"), "w") do io
        @printf(io, "# x  y  z  wx  wy  wz\n")
        step = max(1, length(sol.u) ÷ 15)
        for k in 1:step:length(sol.u)
            u = sol.u[k]
            p = embedding(u[1], u[2])
            J = jacobian(u[1], u[2])
            # Tangent vector in ℝ³
            w3 = J * SVector(u[3], u[4])
            # Scale for visibility
            scale = 0.25
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    p[1], p[2], p[3], scale*w3[1], scale*w3[2], scale*w3[3])
        end
    end

    # Write parallel-transported vector (for geodesic 1 only)
    if i == 1
        open(joinpath(DATADIR, "lec03_parallel_1.dat"), "w") do io
            @printf(io, "# x  y  z  wx  wy  wz\n")
            step = max(1, length(sol.u) ÷ 15)
            for k in 1:step:length(sol.u)
                u = sol.u[k]
                p = embedding(u[1], u[2])
                J = jacobian(u[1], u[2])
                # Parallel-transported vector in ℝ³
                w3 = J * SVector(u[5], u[6])
                scale = 0.25
                @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                        p[1], p[2], p[3], scale*w3[1], scale*w3[2], scale*w3[3])
            end
        end
    end

    @printf("  Geodesic %d: %d points, (θ,φ) final=(%.2f, %.2f)\n",
            i, length(sol.t), sol.u[end][1], sol.u[end][2])

    # Verify unit speed conservation
    let u = sol.u[end]
        g = metric(u[1], u[2])
        speed² = g[1,1]*u[3]^2 + 2g[1,2]*u[3]*u[4] + g[2,2]*u[4]^2
        @printf("    Speed conservation: |v|² = %.8f\n", speed²)
    end

    # Verify parallel transport preserves inner products
    let u = sol.u[end]
        g = metric(u[1], u[2])
        gvw = g[1,1]*u[3]*u[5] + g[1,2]*(u[3]*u[6]+u[4]*u[5]) + g[2,2]*u[4]*u[6]
        wnorm² = g[1,1]*u[5]^2 + 2g[1,2]*u[5]*u[6] + g[2,2]*u[6]^2
        @printf("    g(v,w) = %.8f (should be 0), |w|² = %.8f (should be 1)\n",
                gvw, wnorm²)
    end
end

println("Done. All files in $DATADIR")
