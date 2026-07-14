-- NixOS: Mason descarga binarios genéricos de Linux que no arrancan aquí
-- (enlace dinámico). Se desactiva por completo; los LSP, formatters y
-- linters se toman del PATH: el devshell del flake de cada proyecto
-- (via direnv) o los paquetes del sistema (nil, nixd, etc).
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
}
