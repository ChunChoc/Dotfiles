{ config, pkgs, monitorSettings, ... }:

{
  imports = [
      ./theme.nix
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
  # PAQUETES DE USUARIO
  # --------------------------------------------------------
  home.packages = with pkgs; [
    # GUI Utils
    alacritty fuzzel nautilus vscodium brave
    mpv imv file-roller localsend 
    
    # CLI Utils
    git wget curl tree htop 
    pokeget-rs python3
    
    # System Utils
    xwayland-satellite

    # Fuente
    nerd-fonts.jetbrains-mono
  ];

  # Habilitar fuentes
  fonts.fontconfig.enable = true;

  # --------------------------------------------------------
  # PROGRAMAS CONFIGURADOS EN NIX
  # --------------------------------------------------------
  
  # Directorios XDG (Descargas, Música, etc)
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # Fuzzel (Lanzador)
  programs.fuzzel = {
    enable = true;
    # ... (Aquí puedes dejar tu config de fuzzel o moverla a otro archivo luego)
    settings = {
      main = {
        terminal = "${pkgs.alacritty}/bin/alacritty"; # La magia de Nix
        layer = "overlay";
        width = 30;
        font = "JetBrainsMono Nerd Font:size=10";
        icon-theme = "Papirus-Dark";
        lines = 10;
        horizontal-pad = 20;
        vertical-pad = 20;
        inner-pad = 10;
      };
      
      border = {
        width = 2;
        radius = 10;
      };

      # ESTO ES LA TRADUCCIÓN EXACTA DE "fuzzel.ini" (Catppuccin Mocha)
      colors = {
        background = "1e1e2eff";
        text = "cdd6f4ff";
        match = "cba6f7ff";      # Mauve
        selection = "585b70ff";  # Surface 2
        selection-text = "cdd6f4ff";
        border = "cba6f7ff";     # Mauve
      };
    };
  };

  # ZSH & Starship
  programs.starship.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Historial
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;     # No guardar duplicados
      share = true;          # Compartir historia entre terminales
    };

    # Alias o variables de entorno
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake ~/Dotfiles#nixos-vm";
    };

    # Comandos sueltos
    initContent = ''
      export EDITOR=vim
      pokeget random --hide-name
    '';
  };

  # --------------------------------------------------------
  # PROGRAMAS POR DEFECTO
  # --------------------------------------------------------
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Imágenes -> imv
      "image/jpeg" = [ "imv.desktop" ];
      "image/png"  = [ "imv.desktop" ];
      "image/gif"  = [ "imv.desktop" ];
      "image/webp" = [ "imv.desktop" ];
      
      # Videos -> mpv
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ]; # Archivos .mkv
      "video/webm" = [ "mpv.desktop" ];
      
      # Opcional: Navegador y PDF
      #"text/html" = [ "brave-browser.desktop" ];
      #"application/pdf" = [ "brave-browser.desktop" ]; # O tu visor favorito
    };
  };

  # --------------------------------------------------------
  # NO TOCAR!
  # --------------------------------------------------------
  programs.home-manager.enable = true;
  home.stateVersion = "25.11";
}
