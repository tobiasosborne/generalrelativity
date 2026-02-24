#!/usr/bin/env python3
"""Preprocess GR lecture .tex files for Pandoc conversion.

Strategy: keep most LaTeX intact for pandoc's LaTeX reader.
Only handle things pandoc can't:
- TikZ pictures → placeholders
- Figures with \\input → placeholders
- \\eqbox → \\boxed
- Strip comments and TEX root directives
- \\leavevmode and spacing commands
"""

import re
import sys


def preprocess(tex: str) -> str:
    # Strip TEX root directive
    tex = re.sub(r'%!TEX root.*\n', '', tex)

    # Convert TikZ pictures (inside center or standalone) to placeholders
    tex = re.sub(
        r'\\begin\{center\}\s*\\begin\{tikzpicture\}.*?\\end\{tikzpicture\}\s*\\end\{center\}',
        r'\n\n\\begin{center}\n\\textit{[TikZ diagram --- see PDF]}\n\\end{center}\n\n',
        tex, flags=re.DOTALL
    )
    tex = re.sub(
        r'\\begin\{tikzpicture\}.*?\\end\{tikzpicture\}',
        r'\\textit{[TikZ diagram --- see PDF]}',
        tex, flags=re.DOTALL
    )

    # Handle \\begin{figure}...\\end{figure} with \\input{figures/...}
    def figure_replacer(m):
        caption = ''
        cap_match = re.search(r'\\caption\{(.*?)\}', m.group(0), re.DOTALL)
        if cap_match:
            caption = cap_match.group(1)
            caption = re.sub(r'\\label\{[^}]*\}', '', caption).strip()
            # Clean up LaTeX formatting in caption for display
            caption = caption.replace('~', ' ')
        fig_match = re.search(r'\\input\{figures/([^}]*)\}', m.group(0))
        fig_id = fig_match.group(1) if fig_match else 'figure'
        return f'\n\n\\textit{{[Figure: {caption}]}}\n\n'
    tex = re.sub(r'\\begin\{figure\}.*?\\end\{figure\}', figure_replacer, tex, flags=re.DOTALL)

    # Expand custom macros that pandoc's LaTeX math parser can't handle.
    # MathJax would handle them, but pandoc chokes on them before MathJax
    # gets a chance.  Expand to standard LaTeX equivalents.
    # Expand custom macros so pandoc's LaTeX math parser doesn't choke.
    # Use lambdas for replacements with backreferences to avoid escaping hell.
    tex = re.sub(r'\\Rn\{([^}]*)\}', lambda m: '\\mathbb{R}^{' + m.group(1) + '}', tex)
    tex = re.sub(r'\\M\b', '\\\\mathcal{M}', tex)
    tex = re.sub(r'\\R\b', '\\\\mathbb{R}', tex)
    tex = re.sub(r'\\Tp\b', 'T_p\\\\mathcal{M}', tex)
    tex = re.sub(r'\\Tps\b', 'T_p^*\\\\mathcal{M}', tex)
    tex = re.sub(r'\\covd\b', '\\\\nabla', tex)
    tex = re.sub(r'\\Lie\b', '\\\\mathcal{L}', tex)
    tex = re.sub(r'\\chris\{([^}]*)\}\{([^}]*)\}',
                 lambda m: '\\Gamma^{' + m.group(1) + '}{}_{' + m.group(2) + '}', tex)
    tex = re.sub(r'\\Riem\b', 'R', tex)
    tex = re.sub(r'\\Ric\b', 'R', tex)
    tex = re.sub(r'\\Ein\b', 'G', tex)
    tex = re.sub(r'\\Weyl\b', 'C', tex)
    # Nested-brace-safe patterns for single-arg macros
    nb = r'((?:[^{}]|\{(?:[^{}]|\{[^{}]*\})*\})*)'  # matches nested braces up to depth 2
    tex = re.sub(r'\\vb\{' + nb + r'\}', lambda m: '\\boldsymbol{' + m.group(1) + '}', tex)
    tex = re.sub(r'\\uv\{' + nb + r'\}', lambda m: '\\hat{\\boldsymbol{' + m.group(1) + '}}', tex)
    # \norm needs to handle nested braces
    def expand_norm(m):
        # Find matching brace from position after \norm{
        return '\\lVert ' + m.group(1) + ' \\rVert'
    tex = re.sub(r'\\norm\{((?:[^{}]|\{[^{}]*\})*)\}', expand_norm, tex)
    tex = re.sub(r'\\pd\[([^\]]*)\]\{([^}]*)\}\{([^}]*)\}',
                 lambda m: '\\frac{\\partial^{' + m.group(1) + '} ' + m.group(2) + '}{\\partial {' + m.group(3) + '}^{' + m.group(1) + '}}', tex)
    tex = re.sub(r'\\pd\{([^}]*)\}\{([^}]*)\}',
                 lambda m: '\\frac{\\partial ' + m.group(1) + '}{\\partial ' + m.group(2) + '}', tex)
    tex = re.sub(r'\\td\{([^}]*)\}\{([^}]*)\}',
                 lambda m: '\\frac{d ' + m.group(1) + '}{d ' + m.group(2) + '}', tex)
    tex = re.sub(r'\\dd\b', '\\\\mathrm{d}', tex)
    tex = re.sub(r'\\tp\b', '\\\\otimes', tex)
    tex = re.sub(r'\\ttype\{([^}]*)\}\{([^}]*)\}',
                 lambda m: '\\mathcal{T}(' + m.group(1) + ',' + m.group(2) + ')', tex)
    tex = re.sub(r'\\dt\{([^}]*)\}', lambda m: '\\dot{' + m.group(1) + '}', tex)
    tex = re.sub(r'\\ddt\{([^}]*)\}', lambda m: '\\ddot{' + m.group(1) + '}', tex)
    tex = re.sub(r'\\dalem\b', '\\\\Box', tex)
    tex = re.sub(r'\\lap\b', '\\\\Delta', tex)
    tex = re.sub(r'\\grav\b', 'G', tex)

    # Convert \\eqbox{...} to \\boxed{...}
    tex = re.sub(r'\\eqbox\{([^}]+)\}', r'\\boxed{\\1}', tex)

    # Strip \\leavevmode
    tex = tex.replace('\\leavevmode', '')

    # Convert spacing commands
    tex = tex.replace('\\medskip', '\n')
    tex = tex.replace('\\bigskip', '\n')
    tex = tex.replace('\\smallskip', '\n')

    # Strip \\noindent
    tex = tex.replace('\\noindent', '')

    # Strip \\figbox
    tex = re.sub(r'\\figbox', '', tex)

    return tex


if __name__ == '__main__':
    text = sys.stdin.read()
    print(preprocess(text))
