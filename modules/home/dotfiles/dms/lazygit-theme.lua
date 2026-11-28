local nvim_config, base, cache, delta = unpack(arg)
vim.opt.rtp:prepend(nvim_config)
local theme = require("config.dms_theme")
local p = theme.apply()
if not p then
  return
end
local config = vim.json.decode(table.concat(vim.fn.readfile(base), "\n"))

-- La misma jerarquía que en Snacks: borde activo, superficie de selección y
-- texto legible. Los colores tienen la misma fuente dentro y fuera de Neovim.
config.gui.theme = {
  activeBorderColor = { p.primary, "bold" },
  inactiveBorderColor = { p.outline },
  searchingActiveBorderColor = { p.tertiary, "bold" },
  optionsTextColor = { p.on_surface_variant },
  selectedLineBgColor = { p.surface_container_highest },
  selectedLineFgColor = { p.on_surface },
  inactiveViewSelectedLineBgColor = { p.surface_container_low },
  cherryPickedCommitBgColor = { p.secondary_container },
  cherryPickedCommitFgColor = { p.on_secondary_container },
  unstagedChangesColor = { p.error },
  defaultFgColor = { p.on_surface },
  authorColors = { ["*"] = p.secondary },
}

-- Mantener el color de sintaxis incluso en las palabras que cambiaron.
local removed = theme.blend(p.surface, p.error, 0.14)
local added = theme.blend(p.surface, p.green, 0.14)
local args = {
  "env", "XDG_CACHE_HOME=" .. cache, delta, "--paging=never", "--" .. p.mode,
  "--syntax-theme=dms-lazy",
  "--minus-style=syntax normal", "--plus-style=syntax normal",
  "--minus-emph-style=syntax bold " .. removed, "--plus-emph-style=syntax bold " .. added,
}
config.git.diffRenderers[1].command = table.concat(vim.tbl_map(vim.fn.shellescape, args), " ")

-- Delta usa TextMate. Traducir sus ámbitos a los grupos RGB que ya resolvió
-- Neovim, sin mantener una segunda tabla de colores.
local scopes = {
  { "comment", "Comment" },
  { "string, punctuation.definition.string", "String" },
  { "constant.character.escape, string.regexp, constant.other.placeholder", "@string.escape" },
  { "constant.numeric, constant.language", "Number" },
  { "constant.character", "Character" },
  { "entity.name.function, variable.function", "Function" },
  { "support.function", "@function.builtin" },
  { "support.type, support.class", "@type.builtin" },
  { "support.constant, variable.language", "@variable.builtin" },
  { "entity.name.type, entity.name.class, entity.name.struct, entity.name.enum", "Type" },
  { "storage, keyword", "Keyword" },
  { "keyword.operator", "Operator" },
  { "variable.parameter", "@variable.parameter" },
  { "variable.other.property, variable.other.member, support.type.property-name, meta.object-literal.key", "@property" },
  { "entity.name.tag", "Tag" },
  { "entity.other.attribute-name", "@tag.attribute" },
  { "punctuation", "Delimiter" },
  { "markup.heading", "Title" },
  { "markup.underline.link", "@markup.link.url" },
  { "invalid", "DiagnosticError" },
}
local plist = {
  '<?xml version="1.0" encoding="UTF-8"?>',
  '<plist version="1.0"><dict><key>name</key><string>DMS Lazy</string><key>settings</key><array>',
  ("<dict><key>settings</key><dict><key>foreground</key><string>%s</string>"
    .. "<key>background</key><string>%s</string></dict></dict>"):format(p.on_surface, p.surface),
}
for _, entry in ipairs(scopes) do
  local scope, group = unpack(entry)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  local style = hl.italic and "<key>fontStyle</key><string>italic</string>" or ""
  plist[#plist + 1] = ("<dict><key>scope</key><string>%s</string><key>settings</key><dict>"
    .. "<key>foreground</key><string>#%06x</string>%s</dict></dict>"):format(scope, hl.fg, style)
end
plist[#plist + 1] = "</array></dict></plist>"
io.write(vim.json.encode({ config = config, syntax = table.concat(plist, "\n") }))
