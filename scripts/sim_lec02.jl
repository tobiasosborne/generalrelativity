#!/usr/bin/env julia
# sim_lec02.jl — Geodesics on a Gaussian-bump surface
#
# Surface:  z = h(x,y) = A·exp(-(x²+y²)/(2σ²))  embedded in ℝ³
# Computes: induced metric, Christoffel symbols, geodesic ODE
# Outputs:  surface mesh + 9 initially parallel geodesics
#
# The geodesics all start from x=-2.5 moving purely in the +x direction
# at different y offsets.  The bump deflects them, demonstrating how
# curvature causes initially parallel paths to converge and diverge
# (a precursor to geodesic deviation and gravitational lensing).
#
# Run:  julia --project=. scripts/sim_lec02.jl
# Output: latex/data/lec02_*.dat

using DifferentialEquations
using StaticArrays
using LinearAlgebra
using Printf

const DATADIR = joinpath(@__DIR__, "..", "latex", "data")
mkpath(DATADIR)

# ── Surface definition ──────────────────────────────────────
const A = 1.0
const σ = 1.0
const σ² = σ^2

h(x, y) = A * exp(-(x^2 + y^2) / (2σ²))

# First derivatives
hx(x, y) = -x / σ² * h(x, y)
hy(x, y) = -y / σ² * h(x, y)

# Second derivatives
hxx(x, y) = (-1/σ² + x^2/σ²^2) * h(x, y)
hxy(x, y) = x * y / σ²^2 * h(x, y)
hyy(x, y) = (-1/σ² + y^2/σ²^2) * h(x, y)

# ── Induced metric g_ij = δ_ij + ∂h/∂x^i · ∂h/∂x^j ───────
function metric(x, y)
    fx, fy = hx(x, y), hy(x, y)
    g11 = 1.0 + fx^2
    g12 = fx * fy
    g22 = 1.0 + fy^2
    return SMatrix{2,2}(g11, g12, g12, g22)
end

# ── Metric derivatives ──────────────────────────────────────
# ∂g_ij/∂x and ∂g_ij/∂y
function dmetric(x, y)
    fx  = hx(x, y);   fy  = hy(x, y)
    fxx = hxx(x, y);  fxy = hxy(x, y);  fyy = hyy(x, y)

    # dg/dx
    dg11_dx = 2fx * fxx
    dg12_dx = fxx * fy + fx * fxy
    dg22_dx = 2fy * fxy

    # dg/dy
    dg11_dy = 2fx * fxy
    dg12_dy = fxy * fy + fx * fyy
    dg22_dy = 2fy * fyy

    dgdx = SMatrix{2,2}(dg11_dx, dg12_dx, dg12_dx, dg22_dx)
    dgdy = SMatrix{2,2}(dg11_dy, dg12_dy, dg12_dy, dg22_dy)
    return dgdx, dgdy
end

# ── Christoffel symbols ─────────────────────────────────────
# Γ^λ_{μν} = ½ g^{λσ} (∂g_{σμ}/∂x^ν + ∂g_{σν}/∂x^μ - ∂g_{μν}/∂x^σ)
function christoffel(x, y)
    g = metric(x, y)
    ginv = inv(g)
    dgdx, dgdy = dmetric(x, y)
    dg = (dgdx, dgdy)  # dg[k] = ∂g/∂x^k, k=1→x, k=2→y

    # Γ[λ, μ, ν]
    Γ = zeros(SMatrix{2,2,Float64,4}, 2)  # Γ[λ][μ,ν]

    # Actually compute as a simple 2×2×2 array
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

# ── Verification: compare analytic vs numerical Christoffels ─
function christoffel_numerical(x, y; ε=1e-6)
    G = zeros(2, 2, 2)
    g = metric(x, y)
    ginv = inv(g)

    gxp = metric(x + ε, y); gxm = metric(x - ε, y)
    gyp = metric(x, y + ε); gym = metric(x, y - ε)
    dgdx_num = (gxp - gxm) / (2ε)
    dgdy_num = (gyp - gym) / (2ε)
    dg = (dgdx_num, dgdy_num)

    for λ in 1:2, μ in 1:2, ν in 1:2
        s = 0.0
        for σ in 1:2
            s += ginv[λ, σ] * (dg[ν][σ, μ] + dg[μ][σ, ν] - dg[σ][μ, ν])
        end
        G[λ, μ, ν] = 0.5 * s
    end
    return G
end

# Verification at a test point
let
    x0, y0 = 0.7, 0.3
    Ga = christoffel(x0, y0)
    Gn = christoffel_numerical(x0, y0)
    err = maximum(abs.(Ga .- Gn))
    @printf("Christoffel verification at (%.1f, %.1f): max error = %.2e\n", x0, y0, err)
    @assert err < 1e-5 "Christoffel symbol mismatch!"
end

# ── Geodesic ODE ────────────────────────────────────────────
# State: u = [x, y, vx, vy]
function geodesic!(du, u, p, s)
    x, y, vx, vy = u
    G = christoffel(x, y)
    du[1] = vx
    du[2] = vy
    du[3] = -(G[1,1,1]*vx^2 + 2G[1,1,2]*vx*vy + G[1,2,2]*vy^2)
    du[4] = -(G[2,1,1]*vx^2 + 2G[2,1,2]*vx*vy + G[2,2,2]*vy^2)
end

# ── Surface mesh ────────────────────────────────────────────
const Nm = 50
const mesh_xs = range(-3.0, 3.0, length=Nm)
const mesh_ys = range(-3.0, 3.0, length=Nm)

println("Writing surface mesh $(Nm)×$(Nm)...")
open(joinpath(DATADIR, "lec02_surface.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    for x in mesh_xs
        for y in mesh_ys
            @printf(io, "%.6f  %.6f  %.6f\n", x, y, h(x, y))
        end
        println(io)  # blank line between x-slices
    end
end
println("  Wrote lec02_surface.dat")

# ── Geodesics ───────────────────────────────────────────────
# 9 initially parallel geodesics: all start at x=-2.5, velocity purely +x,
# at y offsets from -1.2 to +1.2.  The bump deflects them symmetrically.
const NGEO = 9
const y_offsets = range(-1.2, 1.2, length=NGEO)
const x_start = -2.5

for (i, y0) in enumerate(y_offsets)
    x0 = x_start
    vx0, vy0 = 1.0, 0.0

    # Normalize initial velocity to unit speed w.r.t. the metric
    g = metric(x0, y0)
    speed² = g[1,1]*vx0^2 + 2g[1,2]*vx0*vy0 + g[2,2]*vy0^2
    vx0 /= sqrt(speed²)
    vy0 /= sqrt(speed²)

    u0 = [x0, y0, vx0, vy0]
    sspan = (0.0, 7.0)

    # Stop if we leave the domain
    domain_check(u, t, integrator) = abs(u[1]) > 3.0 || abs(u[2]) > 3.0
    cb = DiscreteCallback(domain_check, terminate!)

    prob = ODEProblem(geodesic!, u0, sspan)
    sol = solve(prob, Tsit5(); abstol=1e-10, reltol=1e-10,
                saveat=0.04, callback=cb)

    # Write geodesic (x, y, z)
    open(joinpath(DATADIR, "lec02_geodesic_$i.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for u in sol.u
            @printf(io, "%.6f  %.6f  %.6f\n", u[1], u[2], h(u[1], u[2]))
        end
    end

    # Straight line (undeflected path) for comparison
    open(joinpath(DATADIR, "lec02_straight_$i.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for xl in range(x0, 3.0, length=200)
            @printf(io, "%.6f  %.6f  %.6f\n", xl, y0, h(xl, y0))
        end
    end

    @printf("  Geodesic %d: y0=%+5.2f → y_end=%+6.3f  deflection=%+6.3f  (%d pts)\n",
            i, y0, sol.u[end][2], sol.u[end][2] - y0, length(sol.t))

    # Verify unit speed is conserved
    let u = sol.u[end]
        g = metric(u[1], u[2])
        speed² = g[1,1]*u[3]^2 + 2g[1,2]*u[3]*u[4] + g[2,2]*u[4]^2
        @printf("    Speed conservation: |v|² = %.8f (should be 1.0)\n", speed²)
    end
end

println("Done. All files in $DATADIR")
