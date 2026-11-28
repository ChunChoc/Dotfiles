-- Rótulo angular de MaximilianLloyd/ascii.nvim. El separador sigue el borde
-- de la V en cada línea y deja el punto de la i del lado de «Vim».
local logo = {
  "                                              |                       ",
  "       ████ ██████           |█████      ██                     ",
  "      ███████████             |█████                             ",
  "      █████████ ███████████|████████ ███   ███████████   ",
  "     █████████  ███    █████|████████ █████ ██████████████   ",
  "    █████████ ██████████ ██|███████ █████ █████ ████ █████   ",
  "  ███████████ ███    ███ ███|██████ █████ █████ ████ █████  ",
  " ██████  █████████████████████ |████ █████ █████ ████ ██████ ",
}

local plain_logo = (table.concat(logo, "\n"):gsub("|", ""))
local first_line = logo[1]:gsub("|", "")
local width = vim.fn.strdisplaywidth(first_line)

-- Los índices xterm-256 quedan fuera de los 16 colores ANSI que DMS actualiza.
local colors = {
  dark = {
    neo = { fg = "#5fafd7", ctermfg = 74 },
    vim = { fg = "#5faf87", ctermfg = 72 },
  },
  light = {
    neo = { fg = "#0087af", ctermfg = 31 },
    vim = { fg = "#00875f", ctermfg = 29 },
  },
}

local function set_logo_colors()
  local palette = colors[vim.o.background]
  vim.api.nvim_set_hl(0, "NeovimLogoNeo", palette.neo)
  vim.api.nvim_set_hl(0, "NeovimLogoVim", palette.vim)
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("NeovimDashboardLogo", { clear = true }),
  callback = set_logo_colors,
})

---@param ctx { width: number }
local function header(_, ctx)
  set_logo_colors()
  -- Si el rótulo supera el ancho del campo, Snacks centra la línea completa.
  local pad = (" "):rep(math.max(0, math.floor((ctx.width - width) / 2)))
  local texts = {}
  for row, line in ipairs(logo) do
    if row > 1 then
      texts[#texts + 1] = { "\n" }
    end
    local neo, vim_part = line:match("^(.-)|(.*)$")
    texts[#texts + 1] = { pad .. neo, hl = "NeovimLogoNeo" }
    texts[#texts + 1] = { vim_part, hl = "NeovimLogoVim" }
  end
  return texts
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = { header = plain_logo },
        formats = { header = header },
      },
    },
  },
}
