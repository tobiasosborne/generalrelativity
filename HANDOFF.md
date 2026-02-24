# Handoff: General Relativity Lecture Notes

## Repo

`/home/tobiasosborne/Projects/generalrelativity` — git, `master` branch.
Public: https://github.com/tobiasosborne/generalrelativity (Apache 2.0)

## Status

15 of 23 lectures converted (+ 1 supplementary note). 82 pages total.
Lectures 1–11 enriched with transcript material.
Lectures 12–15 created via full workflow (PDF + transcript).
Julia simulation pipeline operational: 3 scripts generating data-driven pgfplots figures.
Interactive web version: trial deployed at https://tobiasosborne.github.io/generalrelativity/ (Lecture 3 + interactive geodesic figure).
Build tool: `./build.sh` with `--cmfonts`, `--draft`, `--simdata`, `--full`, `--clean`, `--watch` options.

| Done | Transcript-enriched | Next |
|------|---------------------|------|
| Lec 1: Prerelativity gravitation + Lagrange point figure | ✓ | Lec 15–18: Schwarzschild solution & geodesics |
| Lec 2: Equivalence principle & Mach + parallel geodesic bump figure | ✓ | Lec 19–22: FLRW cosmology |
| Lec 3: Manifolds + ellipsoid geodesics figure | ✓ | |
| Lec 4: Tangent space | ✓ | |
| Lec 5: Flows and tensors | ✓ | |
| Lec 6: Tensors continued (cotangent, transformation laws, metric, AIN) | ✓ | |
| Lec 7: Derivative operators (affine connections, C tensor, Christoffel) | ✓ | |
| Lec 8: Parallel transport (Levi-Civita, metric compatibility, geodesics) | ✓ | |
| Lec 9: Abstract index notation review, curvature intro | ✓ | |
| Lec 10: Geodesics as extremal curves, Riemann tensor, loops | ✓ | |
| Lec 11: Riemann symmetries, Bianchi, Ricci, Einstein tensor, geodesic deviation | ✓ | |
| Lec 12: Lie derivatives, Killing vectors, Einstein's eqs, linearised gravity, Newtonian limit | ✓ | |
| Lec 13: Properties of EFE, linearised derivation details, maps between manifolds | ✓ | |
| Lec 14: Gravitational radiation (TT gauge, plane waves, polarizations, 2+1d, LIGO), homogeneity & isotropy | ✓ | |
| Lec 15: Spaces of constant curvature (eigenvalue argument), S³/R³/H³, FLRW metric | ✓ | |
| Note: ∂_a as covariant derivative | | |

## Lecture-to-PDF mapping

The 23 lecture PDFs in `Lecture Notes/` map as follows:
| Lec | PDF filename (after "Introduction to general relativity") |
|-----|----------------------------------------------------------|
| 1 | prerelativity gravitation |
| 2 | The equivalence principle and Mach's principle |
| 3 | manifolds |
| 4 | tangent space |
| 5 | flows and tensors |
| 6 | tensors continued |
| 7 | abstract index notation curvature (pages 1–8, AIN + curvature motivation) |
| 8 | derivative operators and parallel transport |
| 9 | parallel transport continued |
| 10 | Geodesics cont. curvature |
| 11 | curvature cont. |
| 12 | lie derivatives & Newtonian limit |
| 13 | Einstein's field equations, linearised solutions |
| 14 | gravitational radiation |
| 15 | the Schwarzschild solution |
| 16 | the Schwarzschild solution cont |
| 17 | geodesics in Schwarzschild |
| 18 | trajectories of null geodesics in Schwarzschild |
| 19 | homogeneity and isotropy cont |
| 20 | homogeneity and isotropy cont 2 |
| 21 | FLRW cont |
| 22 | FLRW cont 2 |
| 23 | General relativity.pdf |

**NOTE**: The lecture numbering in the .tex files does NOT correspond 1:1 with the PDF numbering above. The content was reorganized for pedagogical flow. For example, AIN content from PDF "abstract index notation curvature" was split across lec06 (AIN basics), lec07 (derivative operators from the "derivative operators" PDF), and lec09 (AIN review + curvature motivation). Always read the PDF content carefully before converting.

Transcripts are available in `transcripts/lec##_transcript.txt` for all 23 lectures.

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
    lec01.tex – lec13.tex     # Converted lectures
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

Requires: xelatex, Times LT Std, Whitney, mtpro2 (all installed locally).
Whitney fonts symlinked to `~/texmf/fonts/opentype/whitney/`.

## Infrastructure fixes applied

- **gr-macros.sty**: `\pd` macro braces `{#3}` to prevent double-superscript errors
- **gr-style.sty**: Package load order fixed (amsmath/mathtools/tcolorbox loaded before mathspec to avoid conflicts). Added `mathrsfs` for `\mathscr`. Added `notation` theorem environment.

## Workflow per lecture

### For new lectures (lec12 onward): full workflow
1. **Draft**: read handwritten PDF + transcript (`transcripts/lec##_transcript.txt`) → create `lectures/lec##.tex`
2. **Build test**: `./build.sh --draft` — verify zero errors from new lecture
3. **Review**: check content, notation consistency against Wald/Warner
4. **Enhance**: intuition boxes, historical boxes, TikZ diagrams
5. **Simulate** (optional): write `scripts/sim_lec##.jl` → `latex/data/` → `latex/figures/fig_lec##_*.tex`

### For existing lectures (lec03–lec11): transcript enrichment pass
1. **Read** existing `lectures/lec##.tex` + corresponding `transcripts/lec##_transcript.txt`
2. **Identify** motivational discussion, physical intuition, explanatory asides, and pedagogical framing in transcript that are missing from the notes
3. **Edit** the .tex file to weave in transcript material as prose paragraphs, expanded remarks, exercise hints, intuition boxes, or transitional text. Do NOT transcribe verbatim — rewrite in lecture-note style.
4. **Build test**: `./build.sh --draft` — verify zero errors
5. **Guidelines**: keep additions proportionate; add the lecturer's voice and explanatory depth without overwhelming the existing mathematical content. Good candidates: opening/closing motivational paragraphs, "why we care" framing, physical interpretation of formalism, historical/experimental context, forward/backward references between lectures.

## TikZ figure generation from PNG references

**Potrace-based pipeline** (prototyped 2026-02-23 in `temp/`):

1. Convert PNG → PGM: `python3 -c "from PIL import Image; Image.open('input.png').convert('L').save('input.pgm')"`
2. Trace bitmap → SVG: `potrace input.pgm -s -o traced.svg --turdsize 5 --alphamax 1.0`
3. Convert SVG → TikZ: `python3 temp/svg2tikz.py traced.svg 8.0 > output.tex`
4. Compile preview: `scripts/tikz-preview.sh output.tex`

The converter (`temp/svg2tikz.py`) parses potrace SVG path `d` attributes (M, c, C, l, L, h, v, z commands) and emits TikZ `\fill` commands with exact bezier coordinates. Produces geometrically faithful reproductions.

**Next steps for a production figure**:
- Separate the main geometry path (Path 4, ~563 pts) from text glyph paths (small paths)
- Replace `\fill` glyph paths with proper `\node` labels using LaTeX math (`$x^3$`, `$\vb{a}_1$`, etc.)
- Convert filled line paths to `\draw` strokes where appropriate
- Apply project styles (spacecadet, cgblue, axisstyle, vecstyle)

**Lesson learned**: Hand-crafting bezier curves by eye is slow and imprecise. Potrace gives geometrically accurate bezier skeletons that can be post-processed into clean TikZ. The pipeline requires `potrace` (apt package) and Python 3 with PIL.

## Future integration

**Lyr.jl** (`~/Projects/Lyr.jl`): Julia volumetric renderer with planned LyrGR module for Schwarzschild/Kerr geodesic raytracing. Will generate bitmaps for gravitational lensing, redshift, black hole shadows to embed in later lectures.
