{ config, pkgs, monitorSettings, ... }:

{
  imports = [
    ./theme.nix
    ./packages.nix
    ./programs/fuzzel.nix
    ./programs/zsh.nix
    ./mime.nix
  ];

  home.username = "chunchoc";
  home.homeDirectory = "/home/chunchoc";

  # --------------------------------------------------------
  # GESTIÓN DE DOTFILES (Enlazado estático + Generación dinámica)
  # --------------------------------------------------------
  xdg.configFile = {
    # Archivos estáticos (source)
    "alacritty/alacritty.toml".source = ./dotfiles/alacritty/alacritty.toml;
    "starship.toml".source = ./dotfiles/starship/starship.toml;
    "DankMaterialShell/settings.json".source = ./dotfiles/DankMaterialShell/settings.json;
    "niri/config.kdl".source = ./dotfiles/niri/config.kdl;

    # Archivos dinámicos (text + variables)
    "niri/monitors.kdl".text = ''
      output "${monitorSettings.name}" {
          // Monitor generado por Nix
          mode "${toString monitorSettings.width}x${toString monitorSettings.height}@${toString monitorSettings.refreshRate}"
          scale ${toString monitorSettings.scale}
          transform "normal"
          position x=0 y=0
      }
    '';
  };

  # --------------------------------------------------------
  # Directorios XDG
  # --------------------------------------------------------
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # --------------------------------------------------------
  # NO TOCAR!
  # --------------------------------------------------------
  programs.home-manager.enable = true;
  home.stateVersion = "25.11";
}
