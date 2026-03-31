# Birren industrial colour schemes

Colour palettes derived from Faber Birren's industrial safety colour theory (1944), as used in Manhattan Project control rooms and standardised by the National Safety Council. The palette was designed to reduce visual fatigue, signal hazard levels unambiguously, and maintain operator alertness over long shifts. These properties transfer well to code syntax, diagrams, slides, and project branding.

Reference: Beth Mathews, "Why So Many Control Rooms Were Seafoam Green" (2025); Faber Birren, *Color for Interiors: Historical and Modern* (1963).

---

## Base palette

| Role | Name | Hex | Birren function |
|------|------|-----|-----------------|
| Background (fatigue-free) | Seafoam | `#A8D5BA` | Wall colour for sustained attention without eye strain |
| Structure | Medium green | `#5B8C6F` | Dado / lower wall — anchors the visual field |
| Emergency stop | Fire red | `#C4392F` | Fire protection, emergency stops, flammable liquids |
| Caution | Solar yellow | `#E8B630` | Physical hazards, falling risks |
| Hazard | Alert orange | `#D97A2B` | Hazardous machinery parts |
| Safety | Safety green | `#3D7A55` | First aid, emergency exits, eyewash |
| Information | Caution blue | `#4A7FB5` | Non-safety notices, out-of-order signage |
| Infrastructure | Medium gray | `#8C8C84` | Machinery, equipment, racks |
| Warm neutral | Beige | `#D4C9A8` | Interiors without natural light |
| German variant | Cologne bridge green | `#6B8E6B` | RAL 6011 adjacent — cooler, bluer green |

---

## Editor theme: control panel dark

For terminals, editors, and code output. Dark graphite background with Birren signal accents.

| Role | Hex | Use for |
|------|-----|---------|
| Background | `#1E2226` | Editor/terminal background |
| Surface | `#2A2F34` | Panels, selections, gutters |
| Foreground | `#C8D3C0` | Default text (greenish off-white) |
| Seafoam | `#82B896` | Functions, definitions, identifiers |
| Blue | `#6A9EC0` | Types, modules, namespaces |
| Yellow | `#E2C46C` | Strings, numeric literals |
| Orange | `#D4785A` | Keywords, macros, special forms |
| Red | `#C4392F` | Errors, warnings, deprecated |
| Gray | `#8C8C84` | Comments, docstrings |
| Dark green | `#3E5C4A` | Highlight / current-line accent |

## Editor theme: control panel light

Warm off-white background from Birren's recommendation for spaces without natural light.

| Role | Hex | Use for |
|------|-----|---------|
| Background | `#F4F1E8` | Editor background |
| Surface | `#E8E4D8` | Panels, selections |
| Foreground | `#2C3028` | Default text |
| Green | `#3D7A55` | Functions, definitions |
| Blue | `#3A6E8E` | Types, modules |
| Yellow | `#B09830` | Strings, literals |
| Orange | `#B55A38` | Keywords, macros |
| Red | `#A02820` | Errors, warnings |
| Gray | `#8C8C84` | Comments |

---

## Syntax mapping rationale

The mapping from industrial safety roles to code syntax is not arbitrary:

- **Seafoam → functions/defs**: What you look at most. Birren chose seafoam for walls because it reduces fatigue over hours. Functions are the primary reading target in code.
- **Orange → keywords/macros**: "Hazardous machinery" — keywords change control flow and can alter program behaviour non-locally. They deserve visual weight without being alarming.
- **Red → errors only**: Birren reserved red exclusively for fire and emergency stops. Overusing red desensitises. In code, red means something is wrong — nothing else.
- **Yellow → strings/literals**: "Caution" — data that needs careful handling. Strings are injection vectors, literals are magic numbers. Mild visual warning.
- **Blue → types/modules**: "Information" — structural, non-urgent, orienting. Types tell you what something is without demanding immediate action.
- **Gray → comments**: Equipment that recedes into the background. Comments should be readable when sought but not compete with code.
- **Beige background (light theme)**: Birren prescribed beige for windowless rooms. Most offices and lecture halls qualify.

---

## Slide / Beamer palettes

### Oak Ridge (warm institutional)

```latex
\definecolor{birren-bg}{HTML}{E8E4D8}
\definecolor{birren-fg}{HTML}{2C3028}
\definecolor{birren-seafoam}{HTML}{A8D5BA}
\definecolor{birren-green-dark}{HTML}{3E5C4A}
\definecolor{birren-red}{HTML}{C4392F}
\definecolor{birren-orange}{HTML}{D97A2B}
\definecolor{birren-yellow}{HTML}{E8B630}
\definecolor{birren-blue}{HTML}{4A7FB5}
\definecolor{birren-gray}{HTML}{8C8C84}
\definecolor{birren-beige}{HTML}{D4C9A8}

\setbeamercolor{background canvas}{bg=birren-bg}
\setbeamercolor{normal text}{fg=birren-fg}
\setbeamercolor{frametitle}{fg=birren-bg,bg=birren-green-dark}
\setbeamercolor{alerted text}{fg=birren-orange}
\setbeamercolor{structure}{fg=birren-green-dark}
\setbeamercolor{block title}{fg=birren-bg,bg=birren-blue}
\setbeamercolor{block body}{bg=birren-bg!95!birren-fg}
```

### Hanford (cool seafoam)

Background `#D4E8DC`, title bar `#2A5040`, accents: seafoam `#A8D5BA`, blue `#4A7FB5`, orange `#D97A2B`.

### Graphite (dark talk)

Background `#1E2226`, text `#C8D3C0`, accents: seafoam `#82B896`, blue `#6A9EC0`, yellow `#E2C46C`, orange `#D4785A`.

---

## Emacs theme

```elisp
;; birren-reactor-theme.el
(deftheme birren-reactor "Faber Birren industrial safety palette")

(custom-theme-set-faces 'birren-reactor
  '(default                          ((t (:foreground "#C8D3C0" :background "#1E2226"))))
  '(cursor                           ((t (:background "#82B896"))))
  '(region                           ((t (:background "#2A2F34"))))
  '(highlight                        ((t (:background "#3E5C4A"))))
  '(hl-line                          ((t (:background "#252A2E"))))
  '(fringe                           ((t (:background "#1E2226"))))
  '(line-number                      ((t (:foreground "#5A5E58"))))
  '(line-number-current-line         ((t (:foreground "#82B896"))))
  '(font-lock-function-name-face     ((t (:foreground "#82B896"))))
  '(font-lock-variable-name-face     ((t (:foreground "#C8D3C0"))))
  '(font-lock-type-face              ((t (:foreground "#6A9EC0"))))
  '(font-lock-keyword-face           ((t (:foreground "#D4785A"))))
  '(font-lock-string-face            ((t (:foreground "#E2C46C"))))
  '(font-lock-number-face            ((t (:foreground "#E2C46C"))))
  '(font-lock-comment-face           ((t (:foreground "#8C8C84"))))
  '(font-lock-doc-face               ((t (:foreground "#8C8C84" :slant italic))))
  '(font-lock-constant-face          ((t (:foreground "#A8D5BA"))))
  '(font-lock-builtin-face           ((t (:foreground "#D4785A"))))
  '(font-lock-warning-face           ((t (:foreground "#C4392F"))))
  '(font-lock-preprocessor-face      ((t (:foreground "#D97A2B"))))
  '(error                            ((t (:foreground "#C4392F"))))
  '(warning                          ((t (:foreground "#E8B630"))))
  '(success                          ((t (:foreground "#82B896"))))
  '(minibuffer-prompt                ((t (:foreground "#6A9EC0"))))
  '(mode-line                        ((t (:foreground "#C8D3C0" :background "#2A2F34"
                                          :box (:line-width 1 :color "#3E5C4A")))))
  '(mode-line-inactive               ((t (:foreground "#8C8C84" :background "#1E2226"
                                          :box (:line-width 1 :color "#2A2F34"))))))

(provide-theme 'birren-reactor)
```

---

## CSS custom properties

```css
:root {
  --birren-seafoam:     #A8D5BA;
  --birren-green-med:   #5B8C6F;
  --birren-green-dark:  #3E5C4A;
  --birren-red:         #C4392F;
  --birren-yellow:      #E8B630;
  --birren-orange:      #D97A2B;
  --birren-blue:        #4A7FB5;
  --birren-gray:        #8C8C84;
  --birren-beige:       #D4C9A8;
  --birren-bg-warm:     #F4F1E8;
  --birren-bg-dark:     #1E2226;
  --birren-surface:     #2A2F34;
  --birren-fg-light:    #C8D3C0;
  --birren-fg-dark:     #2C3028;
  --birren-cologne:     #6B8E6B;
}
```

---

## Julia

```julia
const BIRREN = (
    seafoam     = "#A8D5BA",
    green_med   = "#5B8C6F",
    green_dark  = "#3E5C4A",
    safety      = "#3D7A55",
    red         = "#C4392F",
    yellow      = "#E8B630",
    orange      = "#D97A2B",
    blue        = "#4A7FB5",
    gray        = "#8C8C84",
    beige       = "#D4C9A8",
    bg_warm     = "#F4F1E8",
    bg_dark     = "#1E2226",
    surface     = "#2A2F34",
    fg_light    = "#C8D3C0",
    fg_dark     = "#2C3028",
    cologne     = "#6B8E6B",
)
```

---

## Diagram usage notes

When building diagrams (SVG, TikZ, Makie, etc.) with these colours:

1. **Background**: use seafoam `#A8D5BA` or beige `#D4C9A8` for poster/diagram backgrounds — never pure white. These reduce contrast fatigue.
2. **Two-accent rule**: pick at most two signal colours per diagram. Orange + blue is a strong default (hazard vs. information). Red + green (error vs. safe) works for binary state diagrams.
3. **Gray for structure**: boxes, arrows, borders, axes — anything that should recede. Use medium gray `#8C8C84` or the dark green `#3E5C4A` for structural elements.
4. **Cologne bridge green** (`#6B8E6B`) works well as a muted alternative to seafoam when you need a less saturated green, e.g. for node fills in graph diagrams.
5. **Dark diagrams**: on dark backgrounds (`#1E2226`), use the lighter variants — seafoam `#82B896`, blue `#6A9EC0`, yellow `#E2C46C`, orange `#D4785A`. The base palette colours are calibrated for light backgrounds.

---

## WCAG contrast notes

On dark background `#1E2226`:
- Foreground `#C8D3C0`: contrast ratio ~10.5:1 (AAA)
- Seafoam `#82B896`: ~6.8:1 (AA large + AAA large)
- Yellow `#E2C46C`: ~8.5:1 (AAA)
- Orange `#D4785A`: ~5.2:1 (AA)
- Blue `#6A9EC0`: ~6.0:1 (AA)
- Gray `#8C8C84`: ~4.7:1 (AA large — acceptable for comments)
- Red `#C4392F`: ~3.6:1 (below AA — fine for errors which are always short and contextual)

On light background `#F4F1E8`:
- Foreground `#2C3028`: ~12.5:1 (AAA)
- Green `#3D7A55`: ~5.0:1 (AA)
- Orange `#B55A38`: ~4.5:1 (AA)
- Blue `#3A6E8E`: ~4.8:1 (AA)
