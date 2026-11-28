return function(p, blend)
  local highlights = {
    RenderMarkdownCode = { bg = p.surface_container_low },
    RenderMarkdownCodeBorder = { link = "RenderMarkdownCode" },
    RenderMarkdownCodeInfo = { fg = p.on_surface_variant },
    RenderMarkdownCodeInline = { fg = p.tertiary, bg = p.surface_container_highest },
    RenderMarkdownInlineHighlight = { fg = p.on_surface, bg = blend(p.surface, p.tertiary, 0.20) },
    RenderMarkdownQuote = { fg = p.secondary },
    RenderMarkdownLink = { fg = p.primary },
    RenderMarkdownWikiLink = { link = "RenderMarkdownLink" },
    RenderMarkdownLinkTitle = { link = "RenderMarkdownLink" },
    RenderMarkdownBullet = { fg = p.secondary },
    RenderMarkdownUnchecked = { fg = p.on_surface_variant },
    RenderMarkdownChecked = { fg = p.green },
    RenderMarkdownTodo = { fg = p.warning },
    RenderMarkdownTableHead = { fg = p.secondary, bold = true },
    RenderMarkdownTableRow = { fg = p.outline },
    RenderMarkdownInfo = { link = "DiagnosticInfo" },
    RenderMarkdownHint = { link = "DiagnosticHint" },
    RenderMarkdownSuccess = { link = "RenderMarkdownChecked" },
    RenderMarkdownWarn = { link = "DiagnosticWarn" },
    RenderMarkdownError = { link = "DiagnosticError" },
    ["@markup.raw.markdown_inline"] = { fg = p.tertiary },
    ["@markup.link.label.markdown_inline"] = { fg = p.primary },
    ["@markup.link.url.markdown_inline"] = { fg = p.secondary, underline = true },
    ["@markup.quote.markdown"] = { fg = p.on_surface_variant },
    ["@markup.list.checked.markdown"] = { link = "RenderMarkdownChecked" },
    ["@markup.list.unchecked.markdown"] = { link = "RenderMarkdownUnchecked" },
  }

  -- Solo los títulos superiores llevan una superficie tintada. Los demás
  -- siguen legibles como texto, sin heredar fondos de DiffAdd o DiffChange.
  local headings = { p.primary, p.secondary, p.tertiary, p.on_surface, p.on_surface, p.on_surface_variant }
  for level, color in ipairs(headings) do
    local text = ("@markup.heading.%d.markdown"):format(level)
    local rendered = "RenderMarkdownH" .. level
    highlights[text] = { fg = color, bold = true }
    highlights[rendered] = { link = text }
    highlights[rendered .. "Bg"] = level <= 2
        and { bg = blend(p.surface, color, level == 1 and 0.16 or 0.10) }
      or { link = text }
  end
  return highlights
end
