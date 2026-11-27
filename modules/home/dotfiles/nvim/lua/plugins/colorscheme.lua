-- Temas integrados en modo ANSI: seguir la paleta de DMS/Alacritty.
return {
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "default" },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options.theme = "16color"
      -- Algunos componentes de LazyVim extraen RGB del tema. Enlazar esos
      -- acentos al resaltado nativo evita convertirlos a colores 16–255.
      for _, section in pairs(opts.sections) do
        for _, component in ipairs(section) do
          if type(component) == "table" then
            if component.color then
              component.color = "Special"
            end
            if component[1] == "diagnostics" then
              component.diagnostics_color = {
                error = { fg = 1 },
                warn = { fg = 3 },
                info = { fg = 4 },
                hint = { fg = 6 },
              }
            elseif component[1] == "diff" then
              component.diff_color = {
                added = { fg = 2 },
                modified = { fg = 3 },
                removed = { fg = 1 },
              }
            elseif component[1] == "filetype" then
              component.colored = false
            end
          end
        end
      end
    end,
  },
}
