-- gr-filter.lua — Pandoc Lua filter for GR lecture notes
-- Converts custom LaTeX environments (which pandoc wraps in Divs) to
-- styled HTML with foldable details/summary elements.

-- Map environment names to display config
local envs = {
  intuition  = { default_title = "Physical intuition",  foldable = true,  open = true,
                 cls = "box-intuition" },
  historical = { default_title = "Historical note",     foldable = true,  open = true,
                 cls = "box-historical" },
  keyresult  = { default_title = "Key result",          foldable = true,  open = true,
                 cls = "box-keyresult" },
  solution   = { default_title = "Solution",            foldable = true,  open = false,
                 cls = "box-solution" },
  definition = { default_title = "Definition",          foldable = false, open = false,
                 cls = "box-definition" },
  exercise   = { default_title = "Exercise",            foldable = false, open = false,
                 cls = "box-exercise" },
  example    = { default_title = "Example",             foldable = false, open = false,
                 cls = "box-example" },
  remark     = { default_title = "Remark",              foldable = false, open = false,
                 cls = "box-remark" },
  note       = { default_title = "Note",                foldable = false, open = false,
                 cls = "box-remark" },
  notation   = { default_title = "Notation",            foldable = false, open = false,
                 cls = "box-notation" },
  theorem    = { default_title = "Theorem",             foldable = false, open = false,
                 cls = "box-theorem" },
  lemma      = { default_title = "Lemma",               foldable = false, open = false,
                 cls = "box-theorem" },
  proposition= { default_title = "Proposition",         foldable = false, open = false,
                 cls = "box-theorem" },
  corollary  = { default_title = "Corollary",           foldable = false, open = false,
                 cls = "box-theorem" },
}

function Div(el)
  for env_name, cfg in pairs(envs) do
    if el.classes:includes(env_name) then
      -- Determine title: check for optional argument in data-latex attr
      local title = cfg.default_title
      local data = el.attributes["data-latex"]
      if data then
        local t = data:match("%[(.-)%]")
        if t and t ~= "" then
          title = t
        end
      end

      -- Render inner content to HTML
      local content = pandoc.write(pandoc.Pandoc(el.content), "html")

      if cfg.foldable then
        local open_attr = cfg.open and " open" or ""
        local html = string.format(
          '<details class="%s"%s>\n<summary>%s</summary>\n<div class="box-body">\n%s\n</div>\n</details>',
          cfg.cls, open_attr, title, content
        )
        return pandoc.RawBlock("html", html)
      else
        local html = string.format(
          '<div class="%s">\n<div class="box-title">%s</div>\n%s\n</div>',
          cfg.cls, title, content
        )
        return pandoc.RawBlock("html", html)
      end
    end
  end
end

-- Handle raw LaTeX blocks that pandoc couldn't parse
function RawBlock(el)
  if el.format == "latex" then
    -- TikZ remnants → placeholder
    if el.text:match("\\begin{tikzpicture}") or el.text:match("TikZ diagram") then
      return pandoc.RawBlock("html",
        '<div class="tikz-placeholder">[TikZ diagram — see PDF]</div>')
    end
    -- \begin{center}...\end{center} with text
    local center_content = el.text:match("\\begin{center}%s*(.-)%s*\\end{center}")
    if center_content then
      -- Strip \textit{} wrapper if present
      local inner = center_content:match("\\textit{(.-)}")
      if inner then
        return pandoc.RawBlock("html",
          '<div class="tikz-placeholder">' .. inner .. '</div>')
      end
    end
  end
end
