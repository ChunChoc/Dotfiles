-- Opciones extra sobre los defaults de LazyVim
-- https://www.lazyvim.org/configuration/general#options

-- Monorepos: la raíz es el repo, no donde se ancle el LSP.
-- Sin esto, abrir un archivo de Front/ hacía que <leader>e (y find/grep)
-- creyeran que la raíz era Front/ y ocultaran el resto del proyecto.
vim.g.root_spec = { { ".git" }, "lsp", "cwd" }
