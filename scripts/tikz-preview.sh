#!/usr/bin/env bash
# tikz-preview.sh — Compile a standalone TikZ snippet and convert to PNG
#
# Usage:
#   ./scripts/tikz-preview.sh <tikz-file.tex>
#   ./scripts/tikz-preview.sh latex/figures/fig_lec01_lagrange.tex
#
# The input file should contain ONLY the TikZ environment (tikzpicture or
# pgfplots axis).  This script wraps it in a standalone document that loads
# the GR style/macro/template packages, compiles with xelatex, and converts
# to PNG.  Data files in latex/data/ are accessible via relative paths.
#
# Output: <tikz-file>.png in the same directory.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <tikz-file.tex>" >&2
  exit 1
fi

INPUT="$(realpath "$1")"
BASENAME="$(basename "$INPUT" .tex)"
DIR="$(dirname "$INPUT")"
LATEX_DIR="$(realpath "$(dirname "$0")/../latex")"
TMPDIR="$(mktemp -d)"

trap 'rm -rf "$TMPDIR"' EXIT

# Build standalone document
cat > "$TMPDIR/preview.tex" << HEREDOC
\\documentclass[tikz,border=5pt]{standalone}
\\usepackage{amsmath,amssymb,mathtools}
\\usepackage{fontspec}
\\usepackage{xcolor}
\\usepackage{tikz}
\\usetikzlibrary{calc,arrows.meta,decorations.markings,patterns,
  positioning,shapes.geometric,backgrounds}
\\usepackage{pgfplots}
\\pgfplotsset{compat=1.18}
\\usepgfplotslibrary{patchplots,fillbetween}
\\usepackage{pgfplotstable}

% Color palette
\\definecolor{spacecadet}{HTML}{0D284C}
\\definecolor{munsell}{HTML}{008FA8}
\\definecolor{banana}{HTML}{FFD932}
\\definecolor{cgblue}{HTML}{007CA5}
\\definecolor{isabelline}{HTML}{EAEDEA}
\\definecolor{light-gray}{gray}{0.85}

% GR macros subset
\\newcommand{\\M}{\\mathcal{M}}
\\newcommand{\\Tp}{T_p\\M}
\\newcommand{\\R}{\\mathbb{R}}
\\newcommand{\\Rn}[1]{\\mathbb{R}^{#1}}
\\newcommand{\\vb}[1]{\\boldsymbol{#1}}
\\newcommand{\\norm}[1]{\\lVert #1 \\rVert}
\\newcommand{\\chris}[2]{\\Gamma^{#1}{}_{#2}}
\\newcommand{\\pd}[3][]{{\\frac{\\partial^{#1} #2}{\\partial #3^{#1}}}}

% TikZ styles from gr-macros
\\tikzset{
  vecstyle/.style={-{Stealth[length=6pt,width=4pt]}, thick, cgblue},
  fieldline/.style={-{Stealth[length=5pt,width=3pt]}, thin, spacecadet},
  axisstyle/.style={-{Stealth[length=6pt,width=4pt]}, thick},
  pointmass/.style={circle, fill=spacecadet, inner sep=2pt},
  testmass/.style={circle, fill=cgblue, inner sep=1.5pt},
  trajectory/.style={dashed, cgblue, thick},
  fieldregion/.style={draw=none, fill=isabelline, rounded corners=3pt},
}

% gr-tikz-templates styles (inline for standalone)
\\pgfplotscreateplotcyclelist{grcolors}{
  {cgblue,   line width=1.0pt},
  {munsell,  line width=1.0pt},
  {banana!80!black, line width=1.0pt},
  {spacecadet, line width=1.0pt},
  {cgblue,   line width=1.0pt, dashed},
  {munsell,  line width=1.0pt, dashed},
}
\\pgfplotsset{
  colormap={grpotential}{
    rgb255(0cm)=(13,40,76)
    rgb255(2cm)=(0,124,165)
    rgb255(4cm)=(234,237,234)
    rgb255(5cm)=(255,217,50)
  },
  colormap={grsurface}{
    rgb255(0cm)=(0,143,168)
    rgb255(3cm)=(234,237,234)
  },
  grplot/.style={
    width=7cm, height=5cm,
    axis lines=left,
    every axis x label/.style={at={(ticklabel* cs:1.0)}, anchor=west, font=\\small},
    every axis y label/.style={at={(ticklabel* cs:1.0)}, anchor=south, font=\\small},
    every axis title/.style={at={(0.5,1.05)}, anchor=south, font=\\sffamily\\small\\bfseries, text=cgblue},
    tick label style={font=\\footnotesize, text=spacecadet},
    axis line style={spacecadet, line width=0.6pt},
    major grid style={light-gray, very thin},
    grid=major,
    cycle list name=grcolors,
    clip=true,
  },
  grplotwide/.style={grplot, width=9cm, height=6cm},
  gr3d/.style={
    width=9cm, height=6cm,
    every axis x label/.style={at={(ticklabel* cs:1.0)}, anchor=west, font=\\small},
    every axis y label/.style={at={(ticklabel* cs:1.0)}, anchor=south, font=\\small},
    every axis z label/.style={at={(ticklabel* cs:1.0)}, anchor=south, font=\\small},
    every axis title/.style={at={(0.5,1.05)}, anchor=south, font=\\sffamily\\small\\bfseries, text=cgblue},
    tick label style={font=\\tiny, text=spacecadet},
    axis line style={spacecadet, line width=0.6pt},
    cycle list name=grcolors,
    colormap name=grsurface,
  },
  grcontour/.style={
    grplotwide,
    view={0}{90},
    colormap name=grpotential,
    colorbar,
    colorbar style={tick label style={font=\\tiny}, width=0.2cm},
  },
}

\\begin{document}
\\input{$INPUT}
\\end{document}
HEREDOC

# Symlink data directory so relative paths like data/lec01_*.dat work
ln -sf "$LATEX_DIR/data" "$TMPDIR/data"

# Compile (run from tmpdir, with TEXINPUTS pointing to latex/ for .sty files)
cd "$TMPDIR"
TEXINPUTS=".:$LATEX_DIR:" xelatex -interaction=nonstopmode preview.tex > /dev/null 2>&1

# Convert to PNG (300 dpi)
if command -v pdftoppm &> /dev/null; then
  pdftoppm -png -r 300 -singlefile preview.pdf "$DIR/$BASENAME"
  echo "Wrote $DIR/$BASENAME.png"
elif command -v convert &> /dev/null; then
  convert -density 300 preview.pdf -quality 95 "$DIR/$BASENAME.png"
  echo "Wrote $DIR/$BASENAME.png"
else
  cp preview.pdf "$DIR/$BASENAME.pdf"
  echo "No pdftoppm/convert found. Wrote $DIR/$BASENAME.pdf"
fi
