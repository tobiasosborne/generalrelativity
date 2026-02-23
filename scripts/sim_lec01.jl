#!/usr/bin/env julia
# sim_lec01.jl — Circular Restricted Three-Body Problem
#
# Computes the effective potential in the co-rotating frame,
# locates the five Lagrange points, and integrates a test-particle
# trajectory near L4.
#
# Run:  julia --project=. scripts/sim_lec01.jl
# Output: latex/data/lec01_*.dat

using DifferentialEquations
using LinearAlgebra
using Printf
using DelimitedFiles

const DATADIR = joinpath(@__DIR__, "..", "latex", "data")
mkpath(DATADIR)

# ── Parameters ──────────────────────────────────────────────
# Dimensionless units: M1+M2=1, separation=1, Ω=1
const μ = 0.01         # mass ratio M2/(M1+M2) — below critical value for L4/L5 stability
const M1pos = (-μ, 0.0)
const M2pos = (1.0 - μ, 0.0)

# ── Effective potential ─────────────────────────────────────
function Φ_eff(x, y)
    r1 = sqrt((x - M1pos[1])^2 + (y - M1pos[2])^2)
    r2 = sqrt((x - M2pos[1])^2 + (y - M2pos[2])^2)
    return -((1 - μ) / r1 + μ / r2 + 0.5 * (x^2 + y^2))
end

function ∇Φ_eff(x, y)
    r1 = sqrt((x - M1pos[1])^2 + (y - M1pos[2])^2)
    r2 = sqrt((x - M2pos[1])^2 + (y - M2pos[2])^2)
    dΦdx = (1 - μ) * (x - M1pos[1]) / r1^3 + μ * (x - M2pos[1]) / r2^3 - x
    dΦdy = (1 - μ) * (y - M1pos[2]) / r1^3 + μ * (y - M2pos[2]) / r2^3 - y
    return (dΦdx, dΦdy)
end

# ── Lagrange points ─────────────────────────────────────────
# L4, L5: equilateral triangle points
const L4 = (0.5 - μ,  sqrt(3) / 2)
const L5 = (0.5 - μ, -sqrt(3) / 2)

# L1, L2, L3: collinear points, solve ∂Φ_eff/∂x = 0 on y=0
function find_collinear_L(x0; tol=1e-12, maxiter=100)
    x = x0
    for _ in 1:maxiter
        r1 = abs(x - M1pos[1])
        r2 = abs(x - M2pos[1])
        # f = ∂Φ_eff/∂x on y=0
        f = (1 - μ) * (x - M1pos[1]) / r1^3 + μ * (x - M2pos[1]) / r2^3 - x
        # f' = ∂²Φ_eff/∂x² on y=0
        fp = -(1 - μ) * (2(x - M1pos[1])^2 - r1^2) / r1^5 -
              μ * (2(x - M2pos[1])^2 - r2^2) / r2^5 - 1.0
        # Wait, let me redo. For y=0:
        # ∂Φ_eff/∂x = (1-μ)(x+μ)/|x+μ|³ + μ(x-1+μ)/|x-1+μ|³ - x
        s1 = sign(x + μ)
        s2 = sign(x - 1 + μ)
        f = (1 - μ) * s1 / (x + μ)^2 * s1 + μ * s2 / (x - 1 + μ)^2 * s2 - x
        # Simpler: just use the vector form
        f = (1 - μ) * (x + μ) / abs(x + μ)^3 + μ * (x - 1 + μ) / abs(x - 1 + μ)^3 - x
        fp = -(1 - μ) * 2.0 / abs(x + μ)^3 + (1 - μ) * 3.0 * (x + μ)^2 / abs(x + μ)^5 -
              μ * 2.0 / abs(x - 1 + μ)^3 + μ * 3.0 * (x - 1 + μ)^2 / abs(x - 1 + μ)^5 - 1.0
        # Actually let me just do it cleanly
        dx = -f / fp
        x += dx
        abs(dx) < tol && break
    end
    return x
end

# Better: use a clean formulation
function dΦdx_on_axis(x)
    r1 = abs(x + μ)
    r2 = abs(x - 1 + μ)
    return (1 - μ) * (x + μ) / r1^3 + μ * (x - 1 + μ) / r2^3 - x
end

function d2Φdx2_on_axis(x)
    r1 = abs(x + μ)
    r2 = abs(x - 1 + μ)
    return (1 - μ) * (1/r1^3 - 3(x + μ)^2/r1^5) +
           μ * (1/r2^3 - 3(x - 1 + μ)^2/r2^5) - 1.0
end

function find_L_newton(x0; tol=1e-12, maxiter=200)
    x = x0
    for _ in 1:maxiter
        f = dΦdx_on_axis(x)
        fp = d2Φdx2_on_axis(x)
        dx = -f / fp
        x += dx
        abs(dx) < tol && return x
    end
    return x
end

# Initial guesses: L1 between M1 and M2, L2 beyond M2, L3 beyond M1
const L1x = find_L_newton(0.5)
const L2x = find_L_newton(1.3)
const L3x = find_L_newton(-1.1)

const L1 = (L1x, 0.0)
const L2 = (L2x, 0.0)
const L3 = (L3x, 0.0)

@printf("Lagrange points:\n")
@printf("  L1 = (%.6f, 0)\n", L1[1])
@printf("  L2 = (%.6f, 0)\n", L2[1])
@printf("  L3 = (%.6f, 0)\n", L3[1])
@printf("  L4 = (%.6f, %.6f)\n", L4[1], L4[2])
@printf("  L5 = (%.6f, %.6f)\n", L5[1], L5[2])

# ── Potential on grid ───────────────────────────────────────
const Nx, Ny = 60, 60
const xs = range(-1.5, 2.0, length=Nx)
const ys = range(-1.5, 1.5, length=Ny)

println("Computing potential grid $(Nx)×$(Ny)...")
open(joinpath(DATADIR, "lec01_potential.dat"), "w") do io
    @printf(io, "# x  y  Phi_eff\n")
    for (i, x) in enumerate(xs)
        for y in ys
            r1 = sqrt((x + μ)^2 + y^2)
            r2 = sqrt((x - 1 + μ)^2 + y^2)
            # Skip points too close to masses
            if r1 < 0.05 || r2 < 0.05
                @printf(io, "%.8f  %.8f  nan\n", x, y)
            else
                @printf(io, "%.8f  %.8f  %.8f\n", x, y, Φ_eff(x, y))
            end
        end
        println(io)  # blank line between x-slices for pgfplots
    end
end
println("  Wrote lec01_potential.dat")

# ── Lagrange points file ────────────────────────────────────
open(joinpath(DATADIR, "lec01_lagrange_points.dat"), "w") do io
    @printf(io, "# x  y  label\n")
    @printf(io, "%.8f  %.8f  L1\n", L1[1], L1[2])
    @printf(io, "%.8f  %.8f  L2\n", L2[1], L2[2])
    @printf(io, "%.8f  %.8f  L3\n", L3[1], L3[2])
    @printf(io, "%.8f  %.8f  L4\n", L4[1], L4[2])
    @printf(io, "%.8f  %.8f  L5\n", L5[1], L5[2])
end
println("  Wrote lec01_lagrange_points.dat")

# ── Trajectory near L4 ─────────────────────────────────────
# Equations of motion in co-rotating frame:
#   ẍ - 2ẏ = -∂Φ_eff/∂x
#   ÿ + 2ẋ = -∂Φ_eff/∂y
function cr3bp!(du, u, p, t)
    x, y, vx, vy = u
    dΦx, dΦy = ∇Φ_eff(x, y)
    du[1] = vx
    du[2] = vy
    du[3] = 2vy - dΦx    # Coriolis + effective potential gradient
    du[4] = -2vx - dΦy
end

# Start near L4 with a small perturbation
u0 = [L4[1] + 0.015, L4[2], 0.0, 0.0]
tspan = (0.0, 50.0)   # ~8 orbital periods for clean tadpole
prob = ODEProblem(cr3bp!, u0, tspan)
sol = solve(prob, Tsit5(); abstol=1e-12, reltol=1e-12, saveat=0.05)

println("Integrating trajectory near L4... $(length(sol.t)) points")
open(joinpath(DATADIR, "lec01_trajectory.dat"), "w") do io
    @printf(io, "# x  y\n")
    for u in sol.u
        @printf(io, "%.8f  %.8f\n", u[1], u[2])
    end
end
println("  Wrote lec01_trajectory.dat")

# ── Mass positions ──────────────────────────────────────────
open(joinpath(DATADIR, "lec01_masses.dat"), "w") do io
    @printf(io, "# x  y  label\n")
    @printf(io, "%.8f  %.8f  M1\n", M1pos[1], M1pos[2])
    @printf(io, "%.8f  %.8f  M2\n", M2pos[1], M2pos[2])
end
println("  Wrote lec01_masses.dat")

println("Done. All files in $DATADIR")
