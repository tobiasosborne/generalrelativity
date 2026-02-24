# Handoff: General Relativity Lecture Notes

## Repo

`/home/tobiasosborne/Projects/generalrelativity` — git, `master` branch.
Public: https://github.com/tobiasosborne/generalrelativity (Apache 2.0)

## Status

**Course complete.** All 23 lectures converted (+ 1 supplementary note). 102 pages total, zero errors.

- Lectures 1–11: enriched with transcript material from earlier conversion pass.
- Lectures 12–23: created via full workflow (handwritten PDF + auto-generated transcript).
- Lecture 23: original closing chapter (retrospective, experimental pillars, outlook) — not a transcription of the summary PDF.
- Julia simulation pipeline: 3 scripts generating data-driven pgfplots figures.
- Interactive web version: deployed at https://tobiasosborne.github.io/generalrelativity/ (Lecture 3 + interactive Gaussian bump geodesic figure).

## Lecture contents

| Lec | Topic | Enriched |
|-----|-------|----------|
| 1 | Prerelativity gravitation + Lagrange point figure | ✓ |
| 2 | Equivalence principle & Mach + parallel geodesic bump figure (9 rays) | ✓ |
| 3 | Manifolds (definition, charts, atlases, examples, smooth maps, diffeomorphisms) | ✓ |
| 4 | Tangent space | ✓ |
| 5 | Flows and tensors | ✓ |
| 6 | Tensors continued (cotangent, transformation laws, metric, AIN) | ✓ |
| 7 | Derivative operators (affine connections, C tensor, Christoffel symbols) | ✓ |
| 8 | Parallel transport (Levi-Civita, metric compatibility, geodesics) | ✓ |
| 9 | Abstract index notation review, curvature intro | ✓ |
| 10 | Geodesics as extremal curves, Riemann tensor, loops | ✓ |
| 11 | Riemann symmetries, Bianchi, Ricci, Einstein tensor, geodesic deviation | ✓ |
| 12 | Lie derivatives, Killing vectors, Einstein's equations, linearised gravity, Newtonian limit | ✓ |
| 13 | Properties of EFE (trace, dust, nonlinearity, self-consistency), linearised derivation, maps between manifolds | ✓ |
| 14 | Gravitational radiation (TT gauge, plane waves, 2 polarizations, no waves in 2+1d, LIGO), homogeneity & isotropy | ✓ |
| 15 | Spaces of constant curvature (Riemann as linear map, eigenvalue argument), S³/R³/H³, FLRW metric | ✓ |
| 16 | FLRW dynamics: dust + radiation stress-energy, cosmological constant Λ, reduction to 2 equations, unified metric | ✓ |
| 17 | Friedmann equations, fluid equation, Λ as dark energy (p = −ρ), universe not static, Hubble's law, Big Bang | ✓ |
| 18 | FLRW exact solutions (dust/radiation × k=+1,0,−1), conservation laws, Big Crunch; Schwarzschild ansatz | ✓ |
| 19 | Deriving Schwarzschild metric: Christoffels, Ricci, fh = 1 trick, f = 1+C/r, C = −2M, singularities | ✓ |
| 20 | Interior solution (perfect fluid star, mass function m(r), TOV equation), geodesic setup (Killing constants) | ✓ |
| 21 | Timelike geodesics: effective potential, −ML²/r³ correction, ISCO at 6M, perihelion precession (Mercury 43″/century) | ✓ |
| 22 | Null geodesics: photon sphere r=3M, capture cross section σ=27πM², light deflection δφ=4M/b (Sun 1.75″), 1919 eclipse | ✓ |
| 23 | Retrospective: 4 axioms, 3 solution strategies, experimental pillars table, advanced topics, closing meditation | ✓ |
| Note | ∂_a as covariant derivative (supplementary) | |

## PDF-to-tex mapping

The lecture numbering in the .tex files was reorganized for pedagogical flow and does NOT correspond 1:1 with the PDF numbering. Key reorderings:

- **Cosmology before Schwarzschild**: the course follows the transcript order (gravitational waves → FLRW → Schwarzschild), not the PDF order (gravitational waves → Schwarzschild → FLRW).
- **AIN split**: PDF "abstract index notation curvature" was split across lec06, lec07, lec09.
- **Lec 23**: original closing chapter, not a transcription of "General relativity.pdf" (which was an overview/summary lecture).

Transcript-to-tex mapping for lectures 12–22:

| tex | transcript | PDF |
|-----|-----------|-----|
| lec12 | lec12, lec13 | lie derivatives, Einstein's field equations |
| lec13 | lec13, lec14 | Einstein's field equations, linearised solutions |
| lec14 | lec15 | gravitational radiation |
| lec15 | lec16 | homogeneity and isotropy cont |
| lec16 | lec17 | homogeneity and isotropy cont 2 |
| lec17 | lec18 | FLRW cont |
| lec18 | lec19 | FLRW cont 2 |
| lec19 | lec20 | the Schwarzschild solution |
| lec20 | lec21 | the Schwarzschild solution cont |
| lec21 | lec22 | geodesics in Schwarzschild |
| lec22 | lec23 | trajectories of null geodesics in Schwarzschild |

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
    lec01.tex – lec23.tex     # All 23 lectures
  notes/
    note_da_covariant_derivative.tex
  figures/
    fig_lec01_lagrange.tex    # Effective potential + L4 tadpole orbit
    fig_lec02_geodesic_bump.tex  # 9 parallel geodesics on Gaussian bump (3D + top-down)
    fig_lec03_ellipsoid.tex   # Ellipsoid geodesics + parallel transport
  data/                       # Julia-generated .dat files (gitignored, regenerable)
scripts/
  sim_lec01.jl                # CR3BP: effective potential, Lagrange points, trajectory
  sim_lec02.jl                # Parallel geodesics on Gaussian bump: metric, Christoffels, ODE
  sim_lec03.jl                # Ellipsoid geodesics + parallel transport
  tikz-preview.sh             # Standalone TikZ snippet → PNG preview
  Project.toml                # Julia env (DifferentialEquations, StaticArrays)
web/
  preprocess.py               # LaTeX macro expansion for pandoc
  gr-filter.lua               # Pandoc Lua filter: custom envs → foldable HTML
  template.html               # HTML template with MathJax + CSS
docs/                         # GitHub Pages (served from master:/docs)
  index.html                  # Lecture index
  lec03.html                  # Lecture 3: Manifolds (with embedded interactive figure)
  geodesic-bump.html          # Standalone interactive geodesic figure
build.sh                      # Build tool (--cmfonts, --draft, --simdata, --full, --clean, --watch)
Literature/                   # Copyrighted books (gitignored)
Lecture Notes/                # 23 source PDFs (handwritten, gitignored)
transcripts/                  # Auto-generated lecture transcripts (lec01–lec23)
```

## Build

```bash
./build.sh              # Full build (3 passes + bibtex)
./build.sh --draft      # Single pass (fast)
./build.sh --cmfonts    # Computer Modern fonts (no proprietary fonts)
./build.sh --simdata    # Regenerate Julia simulation data only
./build.sh --full       # Regenerate data + build PDF
./build.sh --clean      # Remove generated files
./build.sh --watch      # Continuous build on file change
```

Requires: xelatex, Times LT Std, Whitney, mtpro2, lucimatx.
Fonts installed to `~/texmf/` (MTPro2 + LucimaTX texmf trees, Times LT Std + Whitney OTF via fontconfig).
Font maps registered with `updmap-user` (mtpro2.map, lucida.map).

## Possible future work

- **Web version**: convert remaining 22 lectures to HTML (pipeline exists in `web/`), add more interactive figures
- **Interactive figures**: Schwarzschild effective potential, FLRW scale factor evolution, perihelion precession visualization
- **TikZ figures**: add diagrams for lectures 14–23 (currently text-only)
- **Lyr.jl integration** (`~/Projects/Lyr.jl`): Schwarzschild/Kerr geodesic raytracing for gravitational lensing visualizations
- **Exercises**: add solutions appendix
