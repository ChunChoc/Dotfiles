-- Snacks autogenera un tema para lazygit desde el colorscheme y pisa la
-- config del usuario; lo desactivamos para que respete el Catppuccin
-- declarado en ~/.config/lazygit/config.yml (Home Manager).
return {
  {
    "folke/snacks.nvim",
    opts = {
      lazygit = { configure = false },
    },
  },
}
