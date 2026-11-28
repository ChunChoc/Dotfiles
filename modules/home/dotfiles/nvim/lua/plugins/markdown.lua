-- Sin markdownlint: sus reglas de estilo (largo de línea, líneas en blanco
-- alrededor de headings, etc.) no aportan para notas y docs de agentes.
-- El LSP (marksman) y el formato con prettier siguen activos.
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      heading = {
        width = { "block", "block", "full" },
        right_pad = { 1, 1, 0 },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = {}
    end,
  },
}
