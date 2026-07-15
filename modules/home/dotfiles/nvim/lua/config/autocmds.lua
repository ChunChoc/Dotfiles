-- Autocomandos extra sobre los defaults de LazyVim
-- https://www.lazyvim.org/configuration/general#auto-commands

-- LazyVim activa el corrector ortográfico (en inglés) en markdown y texto;
-- como las notas están mayormente en español, solo subraya todo. Apagado.
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.spell = false
  end,
})
