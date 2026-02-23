#!/usr/bin/env bash
# build.sh — Build tool for General Relativity lecture notes
#
# Usage:
#   ./build.sh              Build PDF (full font stack)
#   ./build.sh --cmfonts    Build PDF (Computer Modern, no proprietary fonts)
#   ./build.sh --simdata    Regenerate Julia simulation data only
#   ./build.sh --full       Regenerate data + build PDF
#   ./build.sh --clean      Remove generated files
#   ./build.sh --watch      Continuous build (recompile on file change)
#   ./build.sh --preview <figure.tex>   Preview a single TikZ figure
#
# Options:
#   --cmfonts   Use Computer Modern fonts (portable, no Times LT / Whitney / mtpro2)
#   --draft     Fast single-pass build (no bibtex, no cross-refs)
#   --verbose   Show full xelatex output
#   --help      Show this help

set -euo pipefail

PROJ_ROOT="$(cd "$(dirname "$0")" && pwd)"
LATEX_DIR="$PROJ_ROOT/latex"
SCRIPTS_DIR="$PROJ_ROOT/scripts"
MAIN_TEX="GeneralRelativity.tex"
JOB_NAME="GeneralRelativity"

# ── Defaults ──────────────────────────────────────────────────
CMFONTS=0
DRAFT=0
VERBOSE=0
ACTION="build"

# ── Colours for terminal output ──────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${BLUE}[info]${NC} $*"; }
ok()    { echo -e "${GREEN}[ok]${NC}   $*"; }
err()   { echo -e "${RED}[err]${NC}  $*" >&2; }

# ── Parse arguments ──────────────────────────────────────────
PREVIEW_FILE=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --cmfonts)  CMFONTS=1; shift ;;
        --draft)    DRAFT=1; shift ;;
        --verbose)  VERBOSE=1; shift ;;
        --simdata)  ACTION="simdata"; shift ;;
        --full)     ACTION="full"; shift ;;
        --clean)    ACTION="clean"; shift ;;
        --watch)    ACTION="watch"; shift ;;
        --preview)  ACTION="preview"; PREVIEW_FILE="$2"; shift 2 ;;
        --help|-h)  ACTION="help"; shift ;;
        *)          err "Unknown option: $1"; ACTION="help"; shift ;;
    esac
done

# ── Help ─────────────────────────────────────────────────────
show_help() {
    sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
}

# ── Simulation data ──────────────────────────────────────────
run_simulations() {
    info "Regenerating simulation data..."

    if ! command -v julia &>/dev/null; then
        err "Julia not found. Install Julia 1.11+ to regenerate simulation data."
        return 1
    fi

    info "Installing Julia dependencies..."
    julia --project="$SCRIPTS_DIR" -e 'using Pkg; Pkg.instantiate()' 2>&1

    local scripts=("sim_lec01.jl" "sim_lec02.jl" "sim_lec03.jl")
    for script in "${scripts[@]}"; do
        if [[ -f "$SCRIPTS_DIR/$script" ]]; then
            info "Running $script..."
            julia --project="$SCRIPTS_DIR" "$SCRIPTS_DIR/$script"
            ok "$script completed"
        fi
    done

    ok "All simulation data regenerated in $LATEX_DIR/data/"
}

# ── LaTeX build ──────────────────────────────────────────────
build_pdf() {
    local font_opt=""
    if [[ $CMFONTS -eq 1 ]]; then
        info "Building with Computer Modern fonts (portable mode)"
        font_opt="\PassOptionsToPackage{cmfonts}{gr-style}"
    else
        info "Building with full font stack (Times LT Std + Whitney + mtpro2)"
    fi

    cd "$LATEX_DIR"

    # Check for missing data files
    local missing_data=0
    if [[ ! -d "$LATEX_DIR/data" ]] || [[ -z "$(ls -A "$LATEX_DIR/data" 2>/dev/null)" ]]; then
        missing_data=1
        err "No simulation data found in latex/data/. Run: ./build.sh --simdata"
    fi

    local xelatex_cmd="xelatex -interaction=nonstopmode"
    local redirect=""
    if [[ $VERBOSE -eq 0 ]]; then
        redirect="> /dev/null 2>&1"
    fi

    # Build the preamble injection for cmfonts
    local inject=""
    if [[ $CMFONTS -eq 1 ]]; then
        inject="\PassOptionsToPackage{cmfonts}{gr-style}"
    fi

    if [[ $DRAFT -eq 1 ]]; then
        # Single pass, no bibtex
        info "Draft build (single pass)..."
        if [[ -n "$inject" ]]; then
            eval $xelatex_cmd -jobname="$JOB_NAME" "'${inject}\input{$MAIN_TEX}'" $redirect
        else
            eval $xelatex_cmd "$MAIN_TEX" $redirect
        fi
    else
        # Full build: xelatex → bibtex → xelatex × 2
        info "Pass 1/3..."
        if [[ -n "$inject" ]]; then
            eval $xelatex_cmd -jobname="$JOB_NAME" "'${inject}\input{$MAIN_TEX}'" $redirect
        else
            eval $xelatex_cmd "$MAIN_TEX" $redirect
        fi

        info "BibTeX..."
        bibtex "$JOB_NAME" > /dev/null 2>&1 || true

        info "Pass 2/3..."
        if [[ -n "$inject" ]]; then
            eval $xelatex_cmd -jobname="$JOB_NAME" "'${inject}\input{$MAIN_TEX}'" $redirect
        else
            eval $xelatex_cmd "$MAIN_TEX" $redirect
        fi

        info "Pass 3/3..."
        if [[ -n "$inject" ]]; then
            eval $xelatex_cmd -jobname="$JOB_NAME" "'${inject}\input{$MAIN_TEX}'" $redirect
        else
            eval $xelatex_cmd "$MAIN_TEX" $redirect
        fi
    fi

    # Check for real errors (excluding missing data files)
    local error_count=0
    error_count=$(grep -c "^!" "$JOB_NAME.log" 2>/dev/null) || error_count=0
    local data_errors=0
    data_errors=$(grep "^!" "$JOB_NAME.log" 2>/dev/null | grep -c "pgfplots") || data_errors=0
    local real_errors=$(( error_count - data_errors ))

    local pages="?"
    pages=$(grep -oP '\(\K[0-9]+(?= pages)' "$JOB_NAME.log" 2>/dev/null | tail -1) || pages="?"

    if [[ $real_errors -gt 0 ]]; then
        err "Build completed with $real_errors error(s). Check $JOB_NAME.log"
        grep "^!" "$JOB_NAME.log" | grep -v "pgfplots" | sort | uniq -c | sort -rn
    fi

    if [[ $missing_data -eq 1 && $data_errors -gt 0 ]]; then
        info "$data_errors missing data file warning(s) — run ./build.sh --simdata to fix"
    fi

    ok "Built ${BOLD}$JOB_NAME.pdf${NC} ($pages pages)"
    cd "$PROJ_ROOT"
}

# ── Clean ────────────────────────────────────────────────────
clean() {
    info "Cleaning generated files..."
    cd "$LATEX_DIR"
    rm -f "$JOB_NAME".{aux,bbl,blg,log,out,toc,pdf,synctex.gz,fls,fdb_latexmk}
    rm -f lectures/*.aux notes/*.aux
    rm -rf data/
    ok "Cleaned"
    cd "$PROJ_ROOT"
}

# ── Watch ────────────────────────────────────────────────────
watch_build() {
    if ! command -v inotifywait &>/dev/null; then
        err "inotifywait not found. Install inotify-tools: sudo apt install inotify-tools"
        return 1
    fi

    info "Watching for changes in latex/... (Ctrl-C to stop)"
    while true; do
        inotifywait -q -r -e modify,create --include '\.tex$|\.sty$|\.bib$' "$LATEX_DIR"
        info "Change detected, rebuilding..."
        DRAFT=1 build_pdf
    done
}

# ── Preview figure ───────────────────────────────────────────
preview_figure() {
    if [[ -z "$PREVIEW_FILE" ]]; then
        err "No file specified. Usage: ./build.sh --preview <figure.tex>"
        return 1
    fi
    bash "$SCRIPTS_DIR/tikz-preview.sh" "$PREVIEW_FILE"
}

# ── Main dispatch ────────────────────────────────────────────
case "$ACTION" in
    help)     show_help ;;
    simdata)  run_simulations ;;
    build)    build_pdf ;;
    full)     run_simulations && build_pdf ;;
    clean)    clean ;;
    watch)    watch_build ;;
    preview)  preview_figure ;;
esac
