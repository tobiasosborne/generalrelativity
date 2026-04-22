#!/usr/bin/env python3
"""Post-process pandoc HTML output for GR lecture pages.

Swap GRWEBFIGURE:NAME.svg markers (emitted by preprocess.py from bare
\\input{figures/NAME}) for proper <figure><img> HTML. Captions are taken
from a small table below; missing entries get a generic alt text.
"""

import os
import re
import sys

WIDGET_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "widgets")
DOCS_DIR   = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs")

def resolve_figure_ext(stem: str) -> str:
    """Return 'NAME.svg' or 'NAME.png' based on which file exists in docs/."""
    for ext in (".svg", ".png"):
        if os.path.isfile(os.path.join(DOCS_DIR, stem + ext)):
            return stem + ext
    return stem + ".svg"  # fallback for CAPTIONS lookup consistency

# Per-figure captions and alt text.  Keys are SVG filenames.
CAPTIONS = {
    "fig_lec03_chart_single.svg": (
        "A single chart.",
        "Chart ψ<sub>α</sub> : O<sub>α</sub> → U<sub>α</sub> ⊂ ℝ² identifies a "
        "patch of the manifold with an open set in Euclidean space.",
    ),
    "fig_lec03_chart_overlap.svg": (
        "Two overlapping charts and the transition map.",
        "Charts (O<sub>α</sub>, ψ<sub>α</sub>) and (O<sub>β</sub>, ψ<sub>β</sub>) "
        "with overlap O<sub>α</sub> ∩ O<sub>β</sub> (red) on the manifold, and the "
        "transition map ψ<sub>β</sub> ∘ ψ<sub>α</sub><sup>−1</sup> between open "
        "subsets of ℝ².",
    ),
    "fig_lec03_smoothmap.svg": (
        "A smooth map between manifolds and its chart representative.",
        "The smooth map f : ℳ → ℳ′ viewed through charts ψ<sub>α</sub> and "
        "ψ′<sub>β</sub>; the composite ψ′<sub>β</sub> ∘ f ∘ ψ<sub>α</sub><sup>−1</sup> "
        "must be smooth as a map between open subsets of Euclidean space.",
    ),
    "fig_lec04_coord_basis.svg": (
        "Coordinate-basis construction.",
        "For a chart ψ : O → U ⊂ ℝⁿ and a function f : ℳ → ℝ, the composite "
        "f ∘ ψ<sup>−1</sup> : U → ℝ is an ordinary Euclidean-space function, "
        "whose partial derivatives at ψ(p) define the coordinate-basis tangent "
        "vectors.",
    ),
    "fig_lec04_tangent_basis.svg": (
        "Coordinate-basis tangent vectors.",
        "The vectors ∂/∂x¹|<sub>p</sub> and ∂/∂x²|<sub>p</sub> are the "
        "push-forward of the standard basis on ℝ² under Φ = ψ<sup>−1</sup>; "
        "they are genuine tangent vectors to the surface at p.",
    ),
    "fig_lec04_curve.svg": (
        "A smooth curve on a manifold and its tangent vector.",
        "C : ℝ → ℳ is a smooth curve; at each point p = C(t<sub>0</sub>) it "
        "defines a tangent vector T ∈ V<sub>p</sub> via "
        "T(f) = d/dt (f ∘ C) |<sub>t=t<sub>0</sub></sub>.",
    ),
    "fig_lec03_sphere.svg": (
        "The 2-sphere S² with chart patch O<sub>x</sub><sup>+</sup>.",
        "Stereographic-style axes in ℝ³ and the open upper-x hemisphere "
        "O<sub>x</sub><sup>+</sup> = {(x,y,z)∈S² : x > 0}, one of the six "
        "coordinate-halving charts of S².",
    ),
    "fig_lec03_tangent_plane.svg": (
        "Tangent plane to the 2-sphere at a point.",
        "Visualising T<sub>p</sub>ℳ for S² ⊂ ℝ³.  The plane is what one "
        "reaches for when the manifold sits inside an ambient space — but "
        "this picture relies on the embedding, so the next lecture gives "
        "an intrinsic definition.",
    ),
    "fig_lec05_flow.svg": (
        "A one-parameter group of diffeomorphisms.",
        "Vector field v on ℳ (blue arrows) with the integral curve "
        "C<sub>p</sub>(t) = Φ<sub>t</sub>(p) (green) through three points "
        "p, Φ<sub>t</sub>(p), Φ<sub>t+s</sub>(p); the gold arrow at p is "
        "v|<sub>p</sub>, the field value, which is also the tangent to the "
        "orbit at t=0.  Reading the curve left-to-right is the group law "
        "Φ<sub>s</sub> ∘ Φ<sub>t</sub> = Φ<sub>t+s</sub>.",
    ),
    "fig_lec03_ellipsoid.svg": (
        "Geodesics on a triaxial ellipsoid with parallel transport.",
        "Top: geodesics (shortest paths intrinsic to the surface) on a "
        "triaxial ellipsoid (a=1.5, b=1.0, c=0.7).  Bottom: tangent "
        "vectors (gold) and a parallel-transported vector (teal) along a "
        "geodesic — parallel transport preserves inner products but the "
        "transported vector rotates relative to the tangent direction.",
    ),
}


def swap_markers(html: str) -> str:
    # Pandoc wraps \textit{GRWEBFIGURE:NAME} inside a paragraph as
    # <p><em>GRWEBFIGURE:NAME</em></p>.  NAME may or may not carry an
    # extension; resolve via docs/ state when it doesn't.
    pattern = re.compile(
        r'<p[^>]*>\s*<em>GRWEBFIGURE:([^<]+?)</em>\s*</p>',
        re.DOTALL,
    )

    def repl(m):
        ref = m.group(1).strip()
        svg = ref if ref.endswith((".svg", ".png")) else resolve_figure_ext(ref)
        title, alt = CAPTIONS.get(svg, CAPTIONS.get(
            svg.rsplit(".", 1)[0] + ".svg", (None, svg)))
        # Caption renders as HTML → style subscripts; alt attribute is plain text.
        alt_plain = alt.replace("<sub>", "").replace("</sub>", "")
        cap_html = ""
        if title:
            cap_html = (
                f'<figcaption style="font-size:0.85em; color:var(--birrengray); '
                f'margin-top:0.4em;"><strong>{title}</strong> {alt}</figcaption>'
            )
        return (
            f'<figure style="text-align:center; margin:1.5em 0;">\n'
            f'  <img src="{svg}" alt="{alt_plain}" style="max-width:100%; height:auto;">\n'
            f'  {cap_html}\n'
            f'</figure>'
        )

    html = pattern.sub(repl, html)

    # Swap GRWEBWIDGET:NAME markers for the contents of web/widgets/NAME.html.
    widget_pattern = re.compile(
        r'<p[^>]*>\s*<em>GRWEBWIDGET:([a-z0-9_-]+)</em>\s*</p>',
        re.DOTALL,
    )

    def widget_repl(m):
        name = m.group(1)
        path = os.path.join(WIDGET_DIR, f"{name}.html")
        if not os.path.isfile(path):
            return (
                f'<div class="tikz-placeholder">[missing widget: {name}]</div>'
            )
        with open(path, "r", encoding="utf-8") as f:
            return f.read()

    return widget_pattern.sub(widget_repl, html)


if __name__ == "__main__":
    sys.stdout.write(swap_markers(sys.stdin.read()))
