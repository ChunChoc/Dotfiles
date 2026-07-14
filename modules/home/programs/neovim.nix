{ config, pkgs, ... }:

{
  # --------------------------------------------------------
  # LazyVim (Neovim como IDE de terminal)
  # --------------------------------------------------------
  # La config Lua vive en el repo como archivos normales (igual que Niri).
  # Se enlaza FUERA de la store con mkOutOfStoreSymlink porque lazy.nvim
  # necesita escribir lazy-lock.json en ~/.config/nvim; un symlink a la
  # store (solo lectura) rompería la instalación de plugins.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Dotfiles/modules/home/dotfiles/nvim";

  home.packages = with pkgs; [
    # LazyVim los usa para pickers, grep y Git UI
    ripgrep
    lazygit

    # Treesitter compila sus parsers en runtime y necesita un compilador C
    # en el PATH incluso fuera de un devshell (p. ej. editando estos dotfiles)
    gcc
  ];

  # direnv + nix-direnv: al entrar al directorio de un proyecto, cualquier
  # proceso (incluido nvim en su propio tab de Herdr) hereda el devshell del
  # flake con sus LSP/formatters, sin tener que correr `nix develop -c nvim`.
  # La integración con Fish es automática al estar programs.fish habilitado.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
