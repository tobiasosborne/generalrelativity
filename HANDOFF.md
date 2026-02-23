# Handoff: General Relativity Lecture Notes

## Repo

`/home/tobias/Projects/generalrelativity` — git, `master` branch.
Public: https://github.com/tobiasosborne/generalrelativity (Apache 2.0)

## Status

3 of 24 lectures converted (+ 1 supplementary note). 14 pages total.
Julia simulation pipeline operational: 3 scripts generating data-driven pgfplots figures.

| Done | Next |
|------|------|
| Lec 1: Prerelativity gravitation + Lagrange point figure | Lec 4: Tangent space |
| Lec 2: Equivalence principle & Mach + geodesic bump figure | Lec 5: Flows and tensors |
| Lec 3: Manifolds + ellipsoid geodesics figure | Lec 6: Tensors continued |
| Note: ∂_a as covariant derivative | |

## Canonical references

- **Primary**: Wald, *General Relativity* (1984) — notes follow Wald closely
- **Differential geometry**: Warner, *Foundations of Differentiable Manifolds and Lie Groups* (1971)
- MTW and others are supplementary, NOT primary sources of truth

## Project structure

```
latex/
  GeneralRelativity.tex       # Master document (amsart class, xelatex)
  gr-style.sty                # Formatting: fonts, colors, theorem envs, tcolorbox
  gr-macros.sty               # GR macro library + TikZ presets
  gr-tikz-templates.sty       # pgfplots styles, colormaps, standard dims, \pic defs
  references.bib              # Bibliography (Wald, MTW, Weinberg, TLL73)
  lectures/
    lec01.tex                 # Prerelativity gravitation
    lec02.tex                 # Equivalence principle & Mach
    lec03.tex                 # Manifolds
  notes/
    note_da_covariant_derivative.tex
  figures/
    fig_lec01_lagrange.tex    # Effective potential + L4 tadpole orbit
    fig_lec02_geodesic_bump.tex  # Geodesics on Gaussian bump (3D + top-down)
    fig_lec03_ellipsoid.tex   # Ellipsoid geodesics + parallel transport
  data/                       # Julia-generated .dat files (gitignored, regenerable)
scripts/
  sim_lec01.jl                # CR3BP: effective potential, Lagrange points, trajectory
  sim_lec02.jl                # Geodesics on Gaussian bump: metric, Christoffels, ODE
  sim_lec03.jl                # Ellipsoid geodesics + parallel transport
  tikz-preview.sh             # Standalone TikZ snippet → PNG preview
  Project.toml                # Julia env (DifferentialEquations, StaticArrays)
Literature/                   # Copyrighted books (gitignored)
Lecture Notes/                # 24 source PDFs (handwritten, gitignored)
```

## Build

```bash
cd latex
xelatex GeneralRelativity.tex
bibtex GeneralRelativity
xelatex GeneralRelativity.tex
xelatex GeneralRelativity.tex
```

Requires: xelatex, Times LT Std, Whitney, mtpro2 (all installed locally).
Portable build (no proprietary fonts): pass `[cmfonts]` option to gr-style.

## Regenerating simulation data

```bash
julia --project=scripts scripts/sim_lec01.jl   # → latex/data/lec01_*.dat
julia --project=scripts scripts/sim_lec02.jl   # → latex/data/lec02_*.dat
julia --project=scripts scripts/sim_lec03.jl   # → latex/data/lec03_*.dat
```

Requires: Julia 1.11+, DifferentialEquations.jl, StaticArrays.jl (installed via `scripts/Project.toml`).

## Infrastructure

- **gr-style.sty**: amsart + mathspec fonts (with `[cmfonts]` fallback), color palette, section formatting, theorem environments, tcolorbox environments (`intuition`, `historical`, `keyresult`), `\eqbox{}`.
- **gr-macros.sty**: `\pd`, `\vb`, `\uv`, `\covd`, `\chris`, `\Riem`, `\Ric`, `\metric`, `\M`, `\R`, `\Rn`, `\norm`, `\dd`, `\dt`, `\ddt`, `\lap`, `\dalem`, `\supp`, `\diag`, plus TikZ styles.
- **gr-tikz-templates.sty**: pgfplots styles (`grplot`, `grplotwide`, `gr3d`, `grcontour`), colormaps (`grpotential`, `grsurface`), color cycle matching palette, `\pic` definitions for manifold blobs/chart regions/tangent planes.

## Simulation details

Each Julia script is self-contained, includes analytic Christoffel symbol verification (agrees with finite-difference to ~10⁻¹¹), and verifies conservation laws (unit speed, inner product preservation).

- **sim_lec01.jl**: Circular restricted 3-body problem (μ=0.01). Effective potential on 60×60 grid, L1–L5 via Newton's method, tadpole orbit near L4 via Tsit5 integrator.
- **sim_lec02.jl**: Gaussian bump surface z=exp(−r²/2). Induced metric g_ij = δ_ij + ∂h/∂x^i ∂h/∂x^j, analytic Christoffel symbols, 4 geodesics + Euclidean straight-line comparisons.
- **sim_lec03.jl**: Triaxial ellipsoid (a=1.5, b=1.0, c=0.7). 6-component ODE: geodesic + parallel transport. Tangent and parallel-transported vectors converted to ℝ³ via Jacobian.

## pgfplots notes

- Max surf grid ~60×60 (TeX memory limit exceeded at ~100×100)
- Data files use `# header` comments — access columns by index (`x index=0` etc.)
- `tikz-preview.sh` compiles standalone TikZ snippets to PNG for visual feedback

## Workflow per lecture

1. **Draft**: read handwritten PDF → create `lectures/lec##.tex`
2. **Review**: check content, errors, notation consistency against Wald/Warner
3. **Enhance**: intuition boxes, historical boxes, TikZ diagrams
4. **Simulate**: write `scripts/sim_lec##.jl` → `latex/data/` → `latex/figures/fig_lec##_*.tex`

## Lecture order (by date)

See memory file `lecture-order.md` for full list with status.

## Future integration

**Lyr.jl** (`~/Projects/Lyr.jl`): Julia volumetric renderer with planned LyrGR module for Schwarzschild/Kerr geodesic raytracing. Will generate bitmaps for gravitational lensing, redshift, black hole shadows to embed in later lectures.
