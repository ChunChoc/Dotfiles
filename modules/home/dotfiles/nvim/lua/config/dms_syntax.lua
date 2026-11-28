-- Matices de referencia para que un wallpaper casi monocromo no vuelva a
-- juntar categorías distintas. DMS tiñe cada uno con su acento actual.
local anchors = {
  dark = {
    call = "#97bbf0",
    keyword = "#ceb1ec",
    type = "#e4cd92",
    literal = "#eab392",
    field = "#98c9df",
    parameter = "#e5a8af",
    escape = "#ebb8db",
    builtin = "#9bceb8",
  },
  light = {
    call = "#28549a",
    keyword = "#6e3c96",
    type = "#76560b",
    literal = "#974b28",
    field = "#245d78",
    parameter = "#8a3c50",
    escape = "#8d3d79",
    builtin = "#22634e",
  },
}

return function(p, blend)
  local s = {}
  for role, color in pairs(anchors[p.mode]) do
    s[role] = blend(color, p.primary, 0.24)
  end

  local highlights = {
    Comment = { fg = p.on_surface_variant, italic = true },
    Todo = { fg = s.type, bold = true },
    String = { fg = p.green },
    Character = { fg = s.builtin },
    SpecialChar = { fg = s.escape },
    Constant = { fg = s.literal },
    Identifier = { fg = p.on_surface },
    Function = { fg = s.call },
    Statement = { fg = s.keyword },
    Type = { fg = s.type },
    PreProc = { fg = s.parameter },
    Operator = { fg = p.secondary },
    Delimiter = { fg = p.on_surface_variant },
    Special = { fg = p.primary },
    Tag = { fg = s.call },
    ["@comment.note"] = { fg = s.field, bold = true },
    ["@keyword.conditional"] = { fg = s.keyword, italic = true },
    ["@variable.parameter"] = { fg = s.parameter },
    ["@property"] = { fg = s.field },
    ["@constant.builtin"] = { fg = s.builtin },
    ["@module"] = { fg = p.secondary },
    ["@markup.heading.2"] = { fg = s.keyword, bold = true },
    ["@markup.heading.3"] = { fg = s.call, bold = true },
    ["@markup.heading.4"] = { fg = s.field, bold = true },
    ["@markup.heading.5"] = { fg = s.type, bold = true },
    ["@markup.heading.6"] = { fg = s.parameter, bold = true },
    ["@markup.link.url"] = { fg = s.field, underline = true },
  }

  -- Tree-sitter y LSP comparten el mismo rol aunque clasifiquen el token
  -- con nombres diferentes.
  local links = {
    Number = "Constant",
    Float = "Number",
    Boolean = "Constant",
    Keyword = "Statement",
    Conditional = "@keyword.conditional",
    Repeat = "Statement",
    Include = "PreProc",
    ["@comment.todo"] = "Todo",
    ["@comment.warning"] = "DiagnosticWarn",
    ["@comment.error"] = "DiagnosticError",
    ["@variable"] = "Identifier",
    ["@variable.member"] = "@property",
    ["@variable.builtin"] = "@constant.builtin",
    ["@variable.parameter.builtin"] = "@constant.builtin",
    ["@function.builtin"] = "@constant.builtin",
    ["@function.macro"] = "PreProc",
    ["@type.builtin"] = "@constant.builtin",
    ["@constructor"] = "Type",
    ["@attribute"] = "PreProc",
    ["@string.escape"] = "SpecialChar",
    ["@string.regexp"] = "SpecialChar",
    ["@string.special.symbol"] = "Constant",
    ["@string.special.url"] = "@markup.link.url",
    ["@lsp.type.property"] = "@property",
    ["@lsp.type.parameter"] = "@variable.parameter",
    ["@lsp.type.enumMember"] = "@property",
    ["@lsp.typemod.function.defaultLibrary"] = "@function.builtin",
    ["@lsp.typemod.method.defaultLibrary"] = "@function.builtin",
    ["@lsp.typemod.variable.defaultLibrary"] = "@variable.builtin",
    ["@lsp.typemod.type.defaultLibrary"] = "@type.builtin",
    ["@tag.attribute"] = "@property",
    ["@tag.builtin"] = "@constant.builtin",
    ["@tag.delimiter"] = "Delimiter",
    ["@markup.raw"] = "String",
    ["@markup.link.label"] = "Function",
  }
  for group, target in pairs(links) do
    highlights[group] = { link = target }
  end
  return highlights
end
