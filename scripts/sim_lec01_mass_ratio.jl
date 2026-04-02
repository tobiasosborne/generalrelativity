#!/usr/bin/env julia
# sim_lec01_mass_ratio.jl — Orbits with varying inertial-to-gravitational mass ratio
#
# Demonstrates the universality of free fall (UFF / weak equivalence principle):
# if m_g/m_I differs from unity, test particles launched from identical initial
# conditions follow different orbits in a Kepler field.
#
# Run:  julia --project=. scripts/sim_lec01_mass_ratio.jl
# Output: latex/data/lec01_mass_ratio_*.dat

using DifferentialEquations
using LinearAlgebra
using Printf
using DelimitedFiles

const DATADIR = joinpath(@__DIR__, "..", "latex", "data")
mkpath(DATADIR)

# ── Parameters ──────────────────────────────────────────────
const GM = 1.0                  # gravitational parameter (dimensionless units)
const r0 = 1.0                  # initial radial distance
const v_circ = sqrt(GM / r0)    # circular velocity at r0

# Start slightly below circular velocity for a visibly elliptical orbit
const v0 = 0.85 * v_circ

# Mass ratios η = m_g / m_I
const etas = [0.85, 0.93, 1.00, 1.07, 1.15]

# Orbital period for η = 1: T = 2π√(a³/GM) where a = semi-major axis.
# For the η = 1 orbit, energy E = ½v0² - GM/r0, so a = -GM/(2E).
const E0 = 0.5 * v0^2 - GM / r0
const a0 = -GM / (2 * E0)
const T0 = 2π * sqrt(a0^3 / GM)

# Integrate for ~2 orbital periods (of the η = 1 orbit)
const tspan = (0.0, 2.0 * T0)

# ── Equations of motion ────────────────────────────────────
# State: u = [x, y, vx, vy]
# ẍ = -η GM x / r³,  ÿ = -η GM y / r³
function kepler!(du, u, η, t)
    x, y, vx, vy = u
    r = sqrt(x^2 + y^2)
    r3 = r^3
    du[1] = vx
    du[2] = vy
    du[3] = -η * GM * x / r3
    du[4] = -η * GM * y / r3
end

# ── Initial conditions ─────────────────────────────────────
# Start at (r0, 0) with velocity (0, v0) — tangential launch
const u0 = [r0, 0.0, 0.0, v0]

# ── Integration and output ─────────────────────────────────
@printf("Mass-ratio orbit simulation\n")
@printf("  GM = %.2f, r0 = %.2f, v0 = %.4f (v_circ = %.4f)\n", GM, r0, v0, v_circ)
@printf("  Reference orbital period T0 = %.4f\n", T0)
@printf("  Integration span: [0, %.4f] (%.1f periods)\n\n", tspan[2], tspan[2]/T0)

for η in etas
    label = @sprintf("%03d", round(Int, 100 * η))
    fname = "lec01_mass_ratio_$(label).dat"

    prob = ODEProblem(kepler!, u0, tspan, η)
    sol = solve(prob, Tsit5(); abstol=1e-12, reltol=1e-12, saveat=0.02)

    open(joinpath(DATADIR, fname), "w") do io
        @printf(io, "# x  y   (eta = %.2f)\n", η)
        for u in sol.u
            @printf(io, "%.8f  %.8f\n", u[1], u[2])
        end
    end
    @printf("  eta = %.2f  ->  %s  (%d points)\n", η, fname, length(sol.t))
end

# ── Starting point + central mass ──────────────────────────
open(joinpath(DATADIR, "lec01_mass_ratio_markers.dat"), "w") do io
    @printf(io, "# x  y  label\n")
    @printf(io, "%.8f  %.8f  start\n", u0[1], u0[2])
    @printf(io, "%.8f  %.8f  centre\n", 0.0, 0.0)
end
println("  Wrote lec01_mass_ratio_markers.dat")

println("\nDone. All files in $DATADIR")
