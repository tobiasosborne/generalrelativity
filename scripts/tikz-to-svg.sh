#!/usr/bin/env bash
# tikz-to-svg.sh — Compile a project TikZ figure to standalone SVG or PNG using
# the real gr-style/gr-macros/gr-tikz-templates so colours/fonts match the PDF.
#
# SVG output uses dvisvgm; this is good for pure-TikZ figures but loses
# pgfplots surf-plot shading (each mesh cell collapses to a flat silhouette).
# For figures containing \addplot3[surf], prefer --png which rasterises the
# PDF via pdftoppm and preserves the full shaded mesh.
#
# Usage:
#   ./scripts/tikz-to-svg.sh [--cmfonts] [--png] [--dpi N] <figure.tex> <output>

CMFONTS=0
MODE="svg"
DPI=220
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cmfonts) CMFONTS=1; shift ;;
    --png)     MODE="png"; shift ;;
    --dpi)     DPI="$2"; shift 2 ;;
    *)         break ;;
  esac
done

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 [--cmfonts] [--png] [--dpi N] <figure.tex> <output>" >&2
  exit 1
fi

INPUT="$(realpath "$1")"
# Resolve OUTPUT to an absolute path even if the file doesn't exist yet
OUTDIR="$(cd "$(dirname "$2")" && pwd)"
OUTPUT="$OUTDIR/$(basename "$2")"

LATEX_DIR="$(realpath "$(dirname "$0")/../latex")"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

CMFONTS_LINE=""
if [[ $CMFONTS -eq 1 ]]; then
  CMFONTS_LINE='\PassOptionsToPackage{cmfonts}{gr-style}'
fi

# Inline the figure with the outer \begin{center}...\end{center} stripped.
# (That wrapper causes "missing \item" errors under standalone class, because
#  tcolorbox/amsthm configure \begin{center} to expect a list context.)
INLINED=$(sed -e '/^\\begin{center}\s*$/d' -e '/^\\end{center}\s*$/d' "$INPUT")

cat > "$TMPDIR/standalone.tex" <<HEREDOC
\documentclass[border=4pt]{standalone}
$CMFONTS_LINE
\usepackage{gr-style}
\usepackage{gr-macros}
\usepackage{gr-tikz-templates}
\begin{document}
$INLINED
\end{document}
HEREDOC

ln -sf "$LATEX_DIR/data" "$TMPDIR/data"
ln -sf "$LATEX_DIR/figures" "$TMPDIR/figures"

cd "$TMPDIR"
# xelatex may return non-zero on recoverable LaTeX-level warnings; rely on
# the actual PDF's existence + size instead.
TEXINPUTS=".:$LATEX_DIR:" xelatex -interaction=nonstopmode standalone.tex > xelatex.log 2>&1 || true

if [[ ! -s standalone.pdf ]]; then
  echo "[err] xelatex produced no PDF — last 40 lines of log:" >&2
  tail -40 xelatex.log >&2
  exit 1
fi

# Fail loudly if the log contains real "!" error lines (ignoring the recoverable
# "missing \item" which we suppress via wrapper stripping above).
if grep -E "^! " xelatex.log >/dev/null 2>&1; then
  echo "[err] xelatex reported errors:" >&2
  grep -A1 "^! " xelatex.log | head -20 >&2
  exit 1
fi

if [[ "$MODE" == "png" ]]; then
  if ! pdftoppm -r "$DPI" -png -singlefile standalone.pdf "${OUTPUT%.png}" > pdftoppm.log 2>&1; then
    echo "[err] pdftoppm failed — log:" >&2
    cat pdftoppm.log >&2
    exit 1
  fi
else
  if ! dvisvgm --pdf --font-format=woff --exact -n standalone.pdf -o "$OUTPUT" > dvisvgm.log 2>&1; then
    echo "[err] dvisvgm failed — log:" >&2
    tail -30 dvisvgm.log >&2
    exit 1
  fi
fi

echo "Wrote $OUTPUT"
