-- Usar el tema DMS generado para Lazygit también en la ventana de Snacks.
return {
  {
    "folke/snacks.nvim",
    opts = {
      lazygit = { configure = false },
    },
  },
}
