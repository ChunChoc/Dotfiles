-- obsidian.nvim (fork comunitario mantenido; el original de epwalsh está
-- archivado). Trabaja directo sobre el vault de Obsidian en markdown plano:
-- wikilinks con autocompletado, backlinks, notas diarias, búsqueda.
-- El renderizado visual lo hace render-markdown.nvim (extra lang.markdown);
-- obsidian.nvim lo detecta y desactiva su propia UI solo.
return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    ft = "markdown",
    cmd = "Obsidian",
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      workspaces = {
        {
          name = "personal",
          path = "~/Documents/Obsidian",
        },
      },
      completion = {
        blink = true, -- LazyVim usa blink.cmp
      },
      picker = {
        name = "snacks.pick", -- LazyVim usa snacks como picker
      },
      -- Solo el comando unificado :Obsidian, sin los :ObsidianXxx viejos
      legacy_commands = false,
    },
    keys = {
      { "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "Obsidian: abrir nota" },
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "Obsidian: nota nueva" },
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Obsidian: buscar en notas" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Obsidian: backlinks" },
      { "<leader>ot", "<cmd>Obsidian today<cr>", desc = "Obsidian: nota de hoy" },
    },
  },
}
