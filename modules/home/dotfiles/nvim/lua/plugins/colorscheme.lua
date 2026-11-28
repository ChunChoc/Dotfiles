-- La interfaz y la sintaxis comparten los roles de color de DMS.
return {
  { "catppuccin/nvim", name = "catppuccin", enabled = false },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = require("config.dms_theme").enable,
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options.theme = require("config.dms_theme").statusline
      opts.sections.lualine_b[1] = { "branch", section_separators = { left = "" } }
      opts.sections.lualine_y[1].section_separators = { right = "" }
    end,
  },
}
