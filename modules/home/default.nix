{ externalOutputs, monitorSettings, ... }:

let
  primaryLogicalWidth = builtins.ceil (monitorSettings.width / monitorSettings.scale);
  renderExternalOutput = output: ''
    output "${output.name}" {
        ${if output ? mode then ''mode "${output.mode}"'' else ""}
        scale ${toString (output.scale or 1)}
        transform "${output.transform or "normal"}"
        position x=${toString (output.positionX or primaryLogicalWidth)} y=${
          toString (output.positionY or 0)
        }
    }
  '';
in

{
  imports = [
    ./theme.nix
    ./packages.nix
    ./localsend.nix
    ./virtualization.nix
    ./programs/fish.nix
    ./programs/fzf.nix
    ./programs/bat.nix
    ./programs/niri-session.nix
    ./programs/ai.nix
    ./programs/claude.nix
    ./programs/zed.nix
    ./programs/neovim.nix
    ./programs/lazygit.nix
    ./programs/ghostty.nix
    ./programs/mpd.nix
    ./programs/cava.nix
    ./mime.nix
    ./wallpaper.nix
    ./clipboard-images.nix
    ./clipboard-privacy.nix
  ];

  home.username = "chunchoc";
  home.homeDirectory = "/home/chunchoc";

  # --------------------------------------------------------
  # GESTIÓN DE DOTFILES (Enlazado estático + Generación dinámica)
  # --------------------------------------------------------
  xdg.configFile = {
    # Archivos estáticos (source)
    "herdr/config.toml".source = ./dotfiles/herdr/config.toml;
    "starship.toml".source = ./dotfiles/starship/starship.toml;
    # La barra `default` va en modo isla (DMS 1.6). `islandReserveThickness 42`
    # mantiene la franja de la barra clásica para que el `struts { top -6 }` de
    # niri/dms/layout.kdl siga cuadrando; `innerPadding 6` + `gap 6 / compact 30`
    # ponen cápsulas e isla en la misma fila de 30 px, a 6 px del borde.
    "DankMaterialShell/settings.json".source = ./dotfiles/DankMaterialShell/settings.json;
    # `customThemeFile` apunta a ~/.local/state/DankMaterialShell/catppuccin-theme.json,
    # que genera wallpaper.nix a partir de themes/catppuccin/theme.json con el
    # acento del wallpaper actual.
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
    "niri/dms/outputs.kdl".text = builtins.concatStringsSep "\n" (
      map renderExternalOutput externalOutputs
    );
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
