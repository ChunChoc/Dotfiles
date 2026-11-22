return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "^3",
    ft = "markdown",
    cmd = "Obsidian",
    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = "notes",
          -- Abrir Neovim desde la raíz de las notas; sin una ruta personal fija.
          path = function()
            return vim.fn.getcwd()
          end,
          strict = true,
        },
      },
      new_notes_location = "current_dir",
      -- No insertar ni reescribir automáticamente metadatos en las notas.
      frontmatter = { enabled = false },
      picker = { name = "snacks.picker" },
      -- LazyVim ya renderiza Markdown con render-markdown.nvim.
      ui = { enable = false },
    },
  },
}
