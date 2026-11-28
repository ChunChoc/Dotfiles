local M = {}
local syntax = require("config.dms_syntax")
local markdown = require("config.dms_markdown")
local name = "dms-lazy"
local directory = vim.fs.joinpath(vim.fs.dirname(vim.fn.stdpath("cache")), "dms")
local filename = "dms-colors.json"
local palette_file = vim.fs.joinpath(directory, filename)
local settings_file = vim.fs.joinpath(vim.fs.dirname(vim.fn.stdpath("config")), "dms", "settings.json")
local palette, watcher

local function read_json(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local contents = file:read("*a")
  file:close()
  local ok, data = pcall(vim.json.decode, contents)
  return ok and type(data) == "table" and data or nil
end

local function is_color(value)
  return type(value) == "string" and value:match("^#%x%x%x%x%x%x$")
end

function M.blend(from, to, amount)
  local channels = {}
  for channel = 2, 6, 2 do
    local a = tonumber(from:sub(channel, channel + 1), 16)
    local b = tonumber(to:sub(channel, channel + 1), 16)
    channels[#channels + 1] = math.floor(a + (b - a) * amount + 0.5)
  end
  return ("#%02x%02x%02x"):format(unpack(channels))
end

local function read_palette()
  local data = read_json(palette_file)
  if not data or type(data.colors) ~= "table" or type(data.dank16) ~= "table" then
    return nil
  end
  local settings = read_json(settings_file)
  local mode = settings and settings.terminalsAlwaysDark == true and "dark" or data.mode
  local colors = data.colors[mode]
  if (mode ~= "dark" and mode ~= "light") or type(colors) ~= "table" then
    return nil
  end

  for _, role in ipairs({
    "surface", "surface_container_low", "surface_container", "surface_container_highest",
    "on_surface", "on_surface_variant", "outline", "outline_variant",
    "primary", "on_primary", "primary_container", "on_primary_container",
    "secondary", "on_secondary", "secondary_container", "on_secondary_container",
    "tertiary", "on_tertiary", "tertiary_container", "on_tertiary_container", "error", "on_error",
  }) do
    if not is_color(colors[role]) then
      return nil
    end
  end
  local green = type(data.dank16.color2) == "table" and data.dank16.color2[mode]
  local yellow = type(data.dank16.color3) == "table" and data.dank16.color3[mode]
  if not is_color(green) or not is_color(yellow) then
    return nil
  end

  colors.mode = mode
  colors.green = M.blend(colors.on_surface, green, 0.65)
  colors.warning = M.blend(colors.on_surface, yellow, 0.75)
  return colors
end

function M.apply()
  -- Conservar la paleta anterior si DMS todavía no publicó un archivo válido.
  palette = read_palette() or palette
  local p = palette
  if p then
    vim.o.background = p.mode
  end
  vim.o.termguicolors = p ~= nil
  vim.cmd.highlight("clear")
  vim.g.colors_name = name
  vim.api.nvim_set_hl(0, "StatusLine", { link = "Normal" })
  vim.api.nvim_set_hl(0, "StatusLineNC", { link = "Normal" })
  if not p then
    return
  end

  -- Como en RMPC: superficie tenue para la fila activa y acentos según función.
  local highlights = {
    Normal = { fg = p.on_surface },
    NormalFloat = { fg = p.on_surface, bg = p.surface_container_low },
    FloatBorder = { fg = p.outline, bg = p.surface_container_low },
    FloatTitle = { fg = p.secondary, bg = p.surface_container_low, bold = true },
    WinSeparator = { fg = p.outline_variant },
    CursorLine = { bg = p.surface_container_low },
    CursorLineNr = { fg = p.primary, bold = true },
    LineNr = { fg = p.outline },
    Visual = { fg = p.on_primary_container, bg = p.primary_container },
    Search = { fg = p.on_tertiary_container, bg = p.tertiary_container },
    CurSearch = { fg = p.on_tertiary, bg = p.tertiary, bold = true },
    Pmenu = { link = "NormalFloat" },
    PmenuSel = { fg = p.on_surface, bg = p.surface_container_highest },
    Directory = { fg = p.secondary },
    Title = { fg = p.primary, bold = true },
    NonText = { fg = p.outline },
    Added = { fg = p.green },
    Changed = { fg = p.tertiary },
    Removed = { fg = p.error },
    SnacksPickerListCursorLine = { bg = p.surface_container_highest },
    SnacksPickerMatch = { fg = p.primary, bold = true },
    SnacksPickerDir = { fg = p.on_surface_variant },
    SnacksPickerTree = { fg = p.outline_variant },
    SnacksPickerListTitle = { link = "FloatTitle" },
    SnacksPickerInputTitle = { link = "FloatTitle" },
  }
  for group, style in pairs(vim.tbl_extend("force", highlights, syntax(p, M.blend), markdown(p, M.blend))) do
    vim.api.nvim_set_hl(0, group, style)
  end
  for severity, color in pairs({ Error = p.error, Warn = p.warning, Info = p.primary, Hint = p.secondary }) do
    vim.api.nvim_set_hl(0, "Diagnostic" .. severity, { fg = color })
    vim.api.nvim_set_hl(0, "DiagnosticUnderline" .. severity, { sp = color, undercurl = true })
  end
  return p
end

function M.statusline()
  if vim.g.colors_name ~= name then
    return "auto"
  end
  local p = palette
  if not p then
    return "16color"
  end

  local function mode(bg, fg)
    return {
      a = { bg = bg, fg = fg, gui = "bold" },
      b = { bg = p.surface_container, fg = p.on_surface },
      c = { bg = p.surface, fg = p.on_surface_variant },
      z = { bg = p.surface_container_low, fg = p.on_surface_variant },
    }
  end
  return {
    normal = mode(p.primary, p.on_primary),
    insert = mode(p.secondary_container, p.on_secondary_container),
    visual = mode(p.tertiary, p.on_tertiary),
    replace = mode(p.error, p.on_error),
    command = mode(p.secondary, p.on_secondary),
    terminal = mode(p.secondary_container, p.on_secondary_container),
    inactive = mode(p.surface_container, p.on_surface_variant),
  }
end

function M.enable()
  vim.cmd.colorscheme(name)
  if watcher then
    return
  end

  -- Vigilar el directorio, porque DMS reemplaza el JSON de forma atómica.
  pcall(vim.fn.mkdir, directory, "p", 448)
  local handle = vim.uv.new_fs_event()
  if not handle then
    return
  end
  local pending = false
  local started = handle:start(directory, {}, function(err, changed)
    if err or (changed and changed ~= filename) or pending then
      return
    end
    pending = true
    vim.defer_fn(function()
      pending = false
      if vim.g.colors_name == name then
        vim.cmd.colorscheme(name)
      end
    end, 120)
  end)
  if started then
    watcher = handle
  else
    handle:close()
  end
end

return M
