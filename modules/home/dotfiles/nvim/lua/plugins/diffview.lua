-- Revisión visual de los cambios que hacen los agentes: diff lado a lado
-- de todo el working tree e historial por archivo.
return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview (working tree)" },
      { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Historial del archivo" },
    },
  },
}
