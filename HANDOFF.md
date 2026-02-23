# Handoff: General Relativity Lecture Notes

## Repo

`/home/tobias/Projects/generalrelativity` — git, `master` branch.

## Status

2 of 24 lectures converted (+ 1 supplementary note). 9 pages total.

| Done | Next |
|------|------|
| Lec 1: Prerelativity gravitation (6 handwritten pp → 5 typeset pp) | Lec 3: Manifolds |
| Lec 2: Equivalence principle & Mach's principle (5 → 4 pp) | Lec 4: Tangent space |
| Note: ∂_a as covariant derivative (1 → 1 pp) | Lec 5: Flows and tensors |

## Project structure

```
latex/
  GeneralRelativity.tex       # Master document (amsart class, xelatex)
  gr-style.sty                # Formatting: fonts, colors, theorem envs, tcolorbox
  gr-macros.sty               # GR macro library + TikZ presets
  references.bib              # Bibliography (Wald, MTW, Weinberg, TLL73)
  lectures/
    lec01.tex                 # Prerelativity gravitation
    lec02.tex                 # Equivalence principle & Mach
  notes/
    note_da_covariant_derivative.tex
  figures/                    # (empty, ready for external figures)
Lecture Notes/                # 24 source PDFs (handwritten)
```

## Build

```bash
cd latex
xelatex GeneralRelativity.tex
bibtex GeneralRelativity
xelatex GeneralRelativity.tex
xelatex GeneralRelativity.tex
```

Requires: xelatex, Times LT Std, Whitney, mtpro2 (all installed).

## Infrastructure

- **gr-style.sty**: amsart + mathspec fonts, cgblue/banana/munsell/spacecadet color palette, section formatting, theorem environments (definition, example, exercise, theorem, remark), custom tcolorbox environments (`intuition`, `historical`, `keyresult`), `\eqbox{}` for highlighted equations.
- **gr-macros.sty**: `\pd`, `\vb`, `\uv`, `\covd`, `\chris`, `\Riem`, `\Ric`, `\metric`, `\M`, `\R`, `\Rn`, `\norm`, `\dd`, `\dt`, `\ddt`, `\lap`, `\dalem`, `\supp`, `\diag`, plus TikZ styles (vecstyle, fieldline, axisstyle, pointmass, testmass, trajectory).

## Workflow per lecture

1. **Draft**: read handwritten PDF → create `lectures/lec##.tex`
2. **Review**: check content fidelity, correct errors, harmonise notation
3. **Enhance**: add intuition boxes, historical context, TikZ diagrams, comparison tables, flowcharts

## Conventions

- Bold vectors: `\vb{x}`, unit vectors: `\uv{x}`
- Greek indices (α,β,μ,ν) for spacetime components; abstract index notation later
- Key equations in `\eqbox{}` (banana highlight)
- Pedagogical asides in `\begin{intuition}...\end{intuition}` (munsell teal)
- Historical context in `\begin{historical}...\end{historical}` (isabelline grey)
- Major results in `\begin{keyresult}...\end{keyresult}` (banana/cgblue frame)

## Lecture order (by date)

See memory file `lecture-order.md` for full list. Confirmed order for Apr 26 batch: equivalence principle → manifolds → tangent space → flows/tensors → tensors continued.

## Future integration

**Lyr.jl** (`~/Projects/Lyr.jl`): Julia volumetric renderer with planned LyrGR module for Schwarzschild/Kerr geodesic raytracing. Will generate bitmaps for gravitational lensing, redshift, black hole shadows to embed in later lectures (Schwarzschild solution, null geodesics, FLRW cosmology).
