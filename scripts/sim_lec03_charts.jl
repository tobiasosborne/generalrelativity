#!/usr/bin/env julia
# sim_lec03_charts.jl — Mathematically specified chart diagrams for Lecture 3.
#
# Surface  M = { (x,y,z) : z = h(x,y) }  with
#    h(x,y) = 0.5·cos(0.9·x) + 0.35·sin(0.6·y)
#
# Chart  ψ_α : O_α → U_α ⊂ R²      defined by vertical projection (x,y,z) ↦ (x,y).
#            O_α is the graph over an ellipse U_α ⊂ R² centred at
#            (0.5, 0.3) with semi-axes (1.4, 0.9) rotated by 25°.
#
# Chart  ψ_β : O_β → U_β ⊂ R²      defined by projection composed with a rigid
#            rotation of angle θ_β = 30° in R².  O_β is the graph over an
#            ellipse E_β ⊂ R² (in (x,y) coords) centred at (1.5, −0.3) with
#            semi-axes (1.3, 0.85) rotated by −15°; U_β is its image under
#            rotation by θ_β.
#
# Transition map  ψ_β∘ψ_α⁻¹ : ψ_α(O_α∩O_β) → ψ_β(O_α∩O_β) is the restriction
# of R_{θ_β} : R² → R² (smooth, nontrivial).
#
# Run:  julia --project=scripts scripts/sim_lec03_charts.jl
# Output: latex/data/lec03_charts_*.dat

using Printf
using LinearAlgebra

const DATADIR = joinpath(@__DIR__, "..", "latex", "data")
mkpath(DATADIR)

# ── Surface definition ─────────────────────────────────────
h(x, y) = 0.5*cos(0.9*x) + 0.35*sin(0.6*y)

# Jacobian of (u,v) ↦ (u, v, h(u,v)) (columns are ∂_u Φ, ∂_v Φ)
∂uΦ(x, y) = (1.0, 0.0, -0.5*0.9*sin(0.9*x))
∂vΦ(x, y) = (0.0, 1.0,  0.35*0.6*cos(0.6*y))

# ── Rotated ellipse parametrisation ────────────────────────
# Boundary at parameter θ ∈ [0, 2π):
function ellipse_point(θ, u₀, v₀, a, b, φ)
    cφ, sφ = cos(φ), sin(φ)
    x = a*cos(θ); y = b*sin(θ)
    return (u₀ + x*cφ - y*sφ, v₀ + x*sφ + y*cφ)
end

# Interior predicate (strict)
function in_ellipse(u, v, u₀, v₀, a, b, φ)
    cφ, sφ = cos(φ), sin(φ)
    du, dv = u - u₀, v - v₀
    x̃ =  du*cφ + dv*sφ
    ỹ = -du*sφ + dv*cφ
    return (x̃/a)^2 + (ỹ/b)^2 < 1
end

# ── Chart parameters ───────────────────────────────────────
# α chart (projection; ellipse U_α lies directly in (x,y) = R² coords)
const α_u₀, α_v₀ = 0.5, 0.3
const α_a, α_b   = 1.4, 0.9
const α_φ        = deg2rad(25)

# β chart (projection ∘ rotation by θ_β).  E_β is the ellipse in (x,y)
# coords; its image U_β = R_{θ_β}(E_β) in R² is plotted for the β panel.
const θ_β        = deg2rad(30)
const β_x₀, β_y₀ = 1.5, -0.3
const β_a, β_b   = 1.3, 0.85
const β_φ_raw    = deg2rad(-15)

# ── Surface mesh ───────────────────────────────────────────
const N = 55
const x_range = range(-3.0, 3.0, length=N)
const y_range = range(-3.0, 3.0, length=N)

println("Writing surface mesh $(N)×$(N)...")
open(joinpath(DATADIR, "lec03_charts_surface.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    for x in x_range
        for y in y_range
            @printf(io, "%.6f  %.6f  %.6f\n", x, y, h(x,y))
        end
        println(io)
    end
end

# ── Ellipse boundaries ─────────────────────────────────────
const Nθ = 240
const θ_range = range(0, 2π, length=Nθ)

# U_α boundary in R² (chart-α image)
open(joinpath(DATADIR, "lec03_charts_Ualpha_boundary.dat"), "w") do io
    @printf(io, "# u  v\n")
    for θ in θ_range
        u, v = ellipse_point(θ, α_u₀, α_v₀, α_a, α_b, α_φ)
        @printf(io, "%.6f  %.6f\n", u, v)
    end
end

# O_α boundary on M (lift via (u,v) ↦ (u,v,h(u,v)))
open(joinpath(DATADIR, "lec03_charts_Oalpha_boundary.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    for θ in θ_range
        u, v = ellipse_point(θ, α_u₀, α_v₀, α_a, α_b, α_φ)
        @printf(io, "%.6f  %.6f  %.6f\n", u, v, h(u,v))
    end
end

# E_β boundary in (x,y) coords (pre-rotation image of O_β under projection)
open(joinpath(DATADIR, "lec03_charts_Ebeta_boundary.dat"), "w") do io
    @printf(io, "# x  y\n")
    for θ in θ_range
        x, y = ellipse_point(θ, β_x₀, β_y₀, β_a, β_b, β_φ_raw)
        @printf(io, "%.6f  %.6f\n", x, y)
    end
end

# U_β boundary in R² — apply R_{θ_β} to E_β
open(joinpath(DATADIR, "lec03_charts_Ubeta_boundary.dat"), "w") do io
    @printf(io, "# u  v\n")
    cθ, sθ = cos(θ_β), sin(θ_β)
    for θ in θ_range
        x, y = ellipse_point(θ, β_x₀, β_y₀, β_a, β_b, β_φ_raw)
        u =  cθ*x - sθ*y
        v =  sθ*x + cθ*y
        @printf(io, "%.6f  %.6f\n", u, v)
    end
end

# O_β boundary on M (lift of E_β)
open(joinpath(DATADIR, "lec03_charts_Obeta_boundary.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    for θ in θ_range
        x, y = ellipse_point(θ, β_x₀, β_y₀, β_a, β_b, β_φ_raw)
        @printf(io, "%.6f  %.6f  %.6f\n", x, y, h(x,y))
    end
end

# ── Filled elliptical patches (interior samples, disc parametrisation) ──
# (r, θ) ∈ [0,1] × [0, 2π).  Uniform grid → pgfplots surf.
const Nr   = 18
const Nφp  = 48
const r_range  = range(0.0, 1.0, length=Nr)
const φp_range = range(0.0, 2π,  length=Nφp)

# α patch on M
open(joinpath(DATADIR, "lec03_charts_Oalpha_patch.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    for r in r_range
        for φp in φp_range
            xr = α_a*r*cos(φp); yr = α_b*r*sin(φp)
            cφ, sφ = cos(α_φ), sin(α_φ)
            u = α_u₀ + xr*cφ - yr*sφ
            v = α_v₀ + xr*sφ + yr*cφ
            @printf(io, "%.6f  %.6f  %.6f\n", u, v, h(u,v))
        end
        println(io)
    end
end

# α patch in R²
open(joinpath(DATADIR, "lec03_charts_Ualpha_patch.dat"), "w") do io
    @printf(io, "# u  v\n")
    for r in r_range
        for φp in φp_range
            xr = α_a*r*cos(φp); yr = α_b*r*sin(φp)
            cφ, sφ = cos(α_φ), sin(α_φ)
            u = α_u₀ + xr*cφ - yr*sφ
            v = α_v₀ + xr*sφ + yr*cφ
            @printf(io, "%.6f  %.6f\n", u, v)
        end
        println(io)
    end
end

# β patch on M
open(joinpath(DATADIR, "lec03_charts_Obeta_patch.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    for r in r_range
        for φp in φp_range
            xr = β_a*r*cos(φp); yr = β_b*r*sin(φp)
            cφ, sφ = cos(β_φ_raw), sin(β_φ_raw)
            x = β_x₀ + xr*cφ - yr*sφ
            y = β_y₀ + xr*sφ + yr*cφ
            @printf(io, "%.6f  %.6f  %.6f\n", x, y, h(x,y))
        end
        println(io)
    end
end

# β patch in R² (rotated by θ_β)
open(joinpath(DATADIR, "lec03_charts_Ubeta_patch.dat"), "w") do io
    @printf(io, "# u  v\n")
    cθ, sθ = cos(θ_β), sin(θ_β)
    for r in r_range
        for φp in φp_range
            xr = β_a*r*cos(φp); yr = β_b*r*sin(φp)
            cφ, sφ = cos(β_φ_raw), sin(β_φ_raw)
            x = β_x₀ + xr*cφ - yr*sφ
            y = β_y₀ + xr*sφ + yr*cφ
            u =  cθ*x - sθ*y
            v =  sθ*x + cθ*y
            @printf(io, "%.6f  %.6f\n", u, v)
        end
        println(io)
    end
end

# ── Shared point p in O_α ∩ O_β ────────────────────────────
const p_x, p_y = 0.95, -0.05
const p_z = h(p_x, p_y)
@assert in_ellipse(p_x, p_y, α_u₀, α_v₀, α_a, α_b, α_φ)      "p not in E_α"
@assert in_ellipse(p_x, p_y, β_x₀, β_y₀, β_a, β_b, β_φ_raw)  "p not in E_β"

# ── Intersection region U_α ∩ E_β  (for fig_lec03_chart_overlap) ──
# Both ellipses are convex ⇒ intersection is convex ⇒ star-shaped from
# any interior point.  Use p as the polar centre; for each angle ψ, the
# intersection boundary lies at r(ψ) = min(r_α(ψ), r_β(ψ)) where r_*(ψ)
# is the positive hit distance of the ray p + r(cosψ, sinψ) with each
# ellipse boundary.

function ray_to_ellipse(cx, cy, dx, dy, u₀, v₀, a, b, φ)
    cφ, sφ = cos(φ), sin(φ)
    ox, oy = cx - u₀, cy - v₀
    # Rotate offset and direction into ellipse-axis frame
    ox′ =  cφ*ox + sφ*oy
    oy′ = -sφ*ox + cφ*oy
    dx′ =  cφ*dx + sφ*dy
    dy′ = -sφ*dx + cφ*dy
    # Solve ((ox′ + r·dx′)/a)² + ((oy′ + r·dy′)/b)² = 1
    A = (dx′/a)^2 + (dy′/b)^2
    B = 2.0*(ox′*dx′/a^2 + oy′*dy′/b^2)
    C = (ox′/a)^2 + (oy′/b)^2 - 1.0
    disc = B^2 - 4.0*A*C
    disc < 0 && return NaN
    sqrtd = sqrt(disc)
    r1 = (-B + sqrtd)/(2.0*A)
    r2 = (-B - sqrtd)/(2.0*A)
    # Positive root; interior centre ⇒ exactly one positive root per ellipse.
    return max(r1, r2)
end

intersect_r(ψ) = min(
    ray_to_ellipse(p_x, p_y, cos(ψ), sin(ψ), α_u₀, α_v₀, α_a, α_b, α_φ),
    ray_to_ellipse(p_x, p_y, cos(ψ), sin(ψ), β_x₀, β_y₀, β_a, β_b, β_φ_raw),
)

# Smooth-curve boundary resolution (2D polygon fill only — cheap).
const ψ_bdry_range = range(0.0, 2π, length=240)
# Coarser surf-mesh resolution for the 3D patch (pgfplots TeX memory limit).
const ψ_surf_range = range(0.0, 2π, length=48)
const Nr_int       = 14

# Boundary in α-chart (x,y) coords
open(joinpath(DATADIR, "lec03_charts_intersect_Ualpha.dat"), "w") do io
    @printf(io, "# u  v\n")
    for ψ in ψ_bdry_range
        r = intersect_r(ψ)
        @printf(io, "%.6f  %.6f\n", p_x + r*cos(ψ), p_y + r*sin(ψ))
    end
end

# Boundary in β-chart coords (rotate α-coords by θ_β)
open(joinpath(DATADIR, "lec03_charts_intersect_Ubeta.dat"), "w") do io
    @printf(io, "# u  v\n")
    cθ, sθ = cos(θ_β), sin(θ_β)
    for ψ in ψ_bdry_range
        r = intersect_r(ψ)
        x = p_x + r*cos(ψ); y = p_y + r*sin(ψ)
        @printf(io, "%.6f  %.6f\n", cθ*x - sθ*y, sθ*x + cθ*y)
    end
end

# Surf patch on M: coarser polar mesh sized to respect pgfplots memory.
open(joinpath(DATADIR, "lec03_charts_intersect_patch_M.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    for rt in range(0.0, 1.0, length=Nr_int)
        for ψ in ψ_surf_range
            r = intersect_r(ψ) * rt
            x = p_x + r*cos(ψ); y = p_y + r*sin(ψ)
            @printf(io, "%.6f  %.6f  %.6f\n", x, y, h(x, y))
        end
        println(io)
    end
end

# ψ_α(p) = (p_x, p_y)
# ψ_β(p) = R_{θ_β}(p_x, p_y)
let (cθ, sθ) = (cos(θ_β), sin(θ_β))
    open(joinpath(DATADIR, "lec03_charts_point_p_M.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        @printf(io, "%.6f  %.6f  %.6f\n", p_x, p_y, p_z)
    end
    open(joinpath(DATADIR, "lec03_charts_point_p_alpha.dat"), "w") do io
        @printf(io, "# u  v\n")
        @printf(io, "%.6f  %.6f\n", p_x, p_y)
    end
    open(joinpath(DATADIR, "lec03_charts_point_p_beta.dat"), "w") do io
        @printf(io, "# u  v\n")
        @printf(io, "%.6f  %.6f\n", cθ*p_x - sθ*p_y, sθ*p_x + cθ*p_y)
    end
    @printf("Point p: M=(%.3f, %.3f, %.3f), ψ_α(p)=(%.3f, %.3f), ψ_β(p)=(%.3f, %.3f)\n",
            p_x, p_y, p_z, p_x, p_y, cθ*p_x - sθ*p_y, sθ*p_x + cθ*p_y)
end

# ══════════════════════════════════════════════════════════════
#  LECTURE 4: coordinate basis, tangent vectors, smooth curve
# ══════════════════════════════════════════════════════════════

# ── Coordinate basis at a point p_cb ───────────────────────
# p_cb is inside U_α, chosen in a slope-bearing region so the tangent
# vectors ∂_u Φ, ∂_v Φ have visibly nonzero z-components.
const p_cb_x, p_cb_y = 0.9, 0.95
const p_cb_z = h(p_cb_x, p_cb_y)
@assert in_ellipse(p_cb_x, p_cb_y, α_u₀, α_v₀, α_a, α_b, α_φ) "p_cb not in U_α"

open(joinpath(DATADIR, "lec03_charts_point_cb_M.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    @printf(io, "%.6f  %.6f  %.6f\n", p_cb_x, p_cb_y, p_cb_z)
end

# Tangent vectors ∂_u Φ, ∂_v Φ at p_cb, scaled for visibility.
let s = 0.9
    ∂u = ∂uΦ(p_cb_x, p_cb_y)
    ∂v = ∂vΦ(p_cb_x, p_cb_y)
    open(joinpath(DATADIR, "lec03_charts_tangent_cb.dat"), "w") do io
        @printf(io, "# x  y  z  vx  vy  vz  (two rows: ∂_u, ∂_v)\n")
        @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                p_cb_x, p_cb_y, p_cb_z, s*∂u[1], s*∂u[2], s*∂u[3])
        @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                p_cb_x, p_cb_y, p_cb_z, s*∂v[1], s*∂v[2], s*∂v[3])
    end
    # Image of p_cb and basis in R² (the basis in chart coords is just (1,0), (0,1))
    open(joinpath(DATADIR, "lec03_charts_point_cb_alpha.dat"), "w") do io
        @printf(io, "# u  v\n")
        @printf(io, "%.6f  %.6f\n", p_cb_x, p_cb_y)
    end
    @printf("Tangent basis at p_cb=(%.3f,%.3f): ∂_u=(%.3f,%.3f,%.3f), ∂_v=(%.3f,%.3f,%.3f)\n",
            p_cb_x, p_cb_y, ∂u[1], ∂u[2], ∂u[3], ∂v[1], ∂v[2], ∂v[3])
end

# ── Smooth curve C(t) on M ─────────────────────────────────
# In chart coordinates: c(t) = (t, 0.7·sin(0.9·t)) for t ∈ [-1.8, 1.8].
# Lift to M via (x,y) ↦ (x, y, h(x,y)).
# Tangent vector dC/dt|_{t₀} = ∂_u Φ · 1 + ∂_v Φ · 0.7·0.9·cos(0.9·t₀).
let
    Nc = 200
    t_range = range(-1.8, 1.8, length=Nc)
    c_xy(t) = (t, 0.7*sin(0.9*t))
    cdot_xy(t) = (1.0, 0.7*0.9*cos(0.9*t))  # in (u,v) basis

    open(joinpath(DATADIR, "lec03_charts_curve_M.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        for t in t_range
            u, v = c_xy(t)
            @printf(io, "%.6f  %.6f  %.6f\n", u, v, h(u,v))
        end
    end
    open(joinpath(DATADIR, "lec03_charts_curve_chart.dat"), "w") do io
        @printf(io, "# u  v  t\n")
        for t in t_range
            u, v = c_xy(t)
            @printf(io, "%.6f  %.6f  %.6f\n", u, v, t)
        end
    end
    # Tangent vector at t₀ = 0 — a canonical "point on the curve"
    let t₀ = 0.0
        u₀, v₀  = c_xy(t₀)
        uv̇      = cdot_xy(t₀)
        ∂u       = ∂uΦ(u₀, v₀)
        ∂v       = ∂vΦ(u₀, v₀)
        T3       = (uv̇[1]*∂u[1] + uv̇[2]*∂v[1],
                    uv̇[1]*∂u[2] + uv̇[2]*∂v[2],
                    uv̇[1]*∂u[3] + uv̇[2]*∂v[3])
        s = 0.9
        open(joinpath(DATADIR, "lec03_charts_curve_tangent.dat"), "w") do io
            @printf(io, "# x  y  z  tx  ty  tz\n")
            @printf(io, "%.6f  %.6f  %.6f  %.6f  %.6f  %.6f\n",
                    u₀, v₀, h(u₀,v₀), s*T3[1], s*T3[2], s*T3[3])
        end
        open(joinpath(DATADIR, "lec03_charts_curve_point.dat"), "w") do io
            @printf(io, "# x  y  z  t\n")
            @printf(io, "%.6f  %.6f  %.6f  %.6f\n", u₀, v₀, h(u₀,v₀), t₀)
        end
        @printf("Curve tangent at t=0: T=(%.3f,%.3f,%.3f)\n", T3[1], T3[2], T3[3])
    end
end

# ── Smooth map f : M → M' (chart-level definition) ─────────
# f̂ : R² → R²  defined by  (u,v) ↦ (u + 0.3·sin(0.8·v),
#                                    v + 0.25·sin(0.5·u))
# f : M → M = M'  given by lift (u,v,h(u,v)) ↦ (f̂(u,v), h(f̂(u,v)))
# Choose M' = M (same surface) so the diagram needs only a single mesh.
# Image f(O_α) is graph over f̂(U_α); its boundary is f̂ applied to
# the boundary of U_α, then lifted to M.
f̂(u, v) = (u + 0.3*sin(0.8*v), v + 0.25*sin(0.5*u))

open(joinpath(DATADIR, "lec03_charts_fUalpha_boundary.dat"), "w") do io
    @printf(io, "# u  v\n")
    for θ in θ_range
        u, v = ellipse_point(θ, α_u₀, α_v₀, α_a, α_b, α_φ)
        uf, vf = f̂(u, v)
        @printf(io, "%.6f  %.6f\n", uf, vf)
    end
end

open(joinpath(DATADIR, "lec03_charts_fOalpha_boundary.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    for θ in θ_range
        u, v = ellipse_point(θ, α_u₀, α_v₀, α_a, α_b, α_φ)
        uf, vf = f̂(u, v)
        @printf(io, "%.6f  %.6f  %.6f\n", uf, vf, h(uf, vf))
    end
end

open(joinpath(DATADIR, "lec03_charts_fOalpha_patch.dat"), "w") do io
    @printf(io, "# x  y  z\n")
    for r in r_range
        for φp in φp_range
            xr = α_a*r*cos(φp); yr = α_b*r*sin(φp)
            cφ, sφ = cos(α_φ), sin(α_φ)
            u = α_u₀ + xr*cφ - yr*sφ
            v = α_v₀ + xr*sφ + yr*cφ
            uf, vf = f̂(u, v)
            @printf(io, "%.6f  %.6f  %.6f\n", uf, vf, h(uf, vf))
        end
        println(io)
    end
end

open(joinpath(DATADIR, "lec03_charts_fUalpha_patch.dat"), "w") do io
    @printf(io, "# u  v\n")
    for r in r_range
        for φp in φp_range
            xr = α_a*r*cos(φp); yr = α_b*r*sin(φp)
            cφ, sφ = cos(α_φ), sin(α_φ)
            u = α_u₀ + xr*cφ - yr*sφ
            v = α_v₀ + xr*sφ + yr*cφ
            uf, vf = f̂(u, v)
            @printf(io, "%.6f  %.6f\n", uf, vf)
        end
        println(io)
    end
end

# Image of the reference point p under f (for the diagram)
let (fp_x, fp_y) = f̂(p_x, p_y)
    open(joinpath(DATADIR, "lec03_charts_fp_M.dat"), "w") do io
        @printf(io, "# x  y  z\n")
        @printf(io, "%.6f  %.6f  %.6f\n", fp_x, fp_y, h(fp_x, fp_y))
    end
    open(joinpath(DATADIR, "lec03_charts_fp_alpha.dat"), "w") do io
        @printf(io, "# u  v\n")
        @printf(io, "%.6f  %.6f\n", fp_x, fp_y)
    end
    @printf("f(p) = (%.3f, %.3f, %.3f)\n", fp_x, fp_y, h(fp_x, fp_y))
end

println("Done. All files in $DATADIR")
