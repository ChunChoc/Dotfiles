{ externalOutputs, monitorSettings, ... }:

let
  primaryLogicalWidth = builtins.ceil (monitorSettings.width / monitorSettings.scale);
  renderExternalOutput = output: ''
    output "${output.name}" {
        ${if output ? mode then ''mode "${output.mode}"'' else ""}
        scale ${toString (output.scale or 1)}
        transform "${output.transform or "normal"}"
        position x=${toString (output.positionX or primaryLogicalWidth)} y=${toString (output.positionY or 0)}
    }
  '';
in

{
  imports = [
    ./theme.nix
    ./packages.nix
    ./localsend.nix
    ./programs/fish.nix
    ./programs/niri-session.nix
    ./programs/ai.nix
    ./programs/claude.nix
    ./programs/zed.nix
    ./programs/tmux.nix
    ./programs/neovim.nix
    ./mime.nix
    ./wallpaper.nix
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
    "starship-dev.toml".source = ./dotfiles/starship/starship-dev.toml;
    "DankMaterialShell/settings.json".source = ./dotfiles/DankMaterialShell/settings.json;
    "DankMaterialShell/themes/catppuccin/theme.json".source = ./dotfiles/DankMaterialShell/themes/catppuccin/theme.json;
    "niri/config.kdl".source = ./dotfiles/niri/config.kdl;
    "niri/dms/alttab.kdl".source = ./dotfiles/niri/dms/alttab.kdl;
    "niri/dms/binds.kdl".source = ./dotfiles/niri/dms/binds.kdl;
    "niri/dms/colors.kdl".source = ./dotfiles/niri/dms/colors.kdl;
    "niri/dms/cursor.kdl".source = ./dotfiles/niri/dms/cursor.kdl;
    "niri/dms/effects.kdl".source = ./dotfiles/niri/dms/effects.kdl;
    "niri/dms/layout.kdl".source = ./dotfiles/niri/dms/layout.kdl;
    "niri/dms/windowrules.kdl".source = ./dotfiles/niri/dms/windowrules.kdl;
    "niri/dms/wpblur.kdl".source = ./dotfiles/niri/dms/wpblur.kdl;

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
    "niri/dms/outputs.kdl".text = builtins.concatStringsSep "\n" (map renderExternalOutput externalOutputs);
  };

  # --------------------------------------------------------
  # Directorios XDG
  # --------------------------------------------------------
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
  };

  # --------------------------------------------------------
  # NO TOCAR!
  # --------------------------------------------------------
  programs.home-manager.enable = true;
  home.stateVersion = "25.11";
}
