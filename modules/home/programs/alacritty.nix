{ config, pkgs, ... }:

{
  home.sessionVariables.TERMINAL = "alacritty";
  systemd.user.sessionVariables.TERMINAL = "alacritty";

  programs.alacritty = {
    enable = true;
    settings = {
      general.working_directory = config.home.homeDirectory;
      terminal.shell.program = "${pkgs.fish}/bin/fish";

      font = {
        normal.family = "JetBrainsMono Nerd Font";
        size = 11;
      };

      window = {
        decorations = "None";
        opacity = 0.95;
      };

      # Colores estáticos por ahora. La integración dinámica con DMS queda
      # pendiente; no importar archivos que matugen pueda sobrescribir.
      colors = {
        transparent_background_colors = false;
        primary = {
          background = "#1e1e2e";
          foreground = "#cdd6f4";
        };
        cursor = {
          cursor = "#cba6f7";
          text = "#1e1e2e";
        };
        selection = {
          background = "#cba6f7";
          text = "#1e1e2e";
        };
        normal = {
          black = "#45475a";
          red = "#f38ba8";
          green = "#a6e3a1";
          yellow = "#f9e2af";
          blue = "#89b4fa";
          magenta = "#cba6f7";
          cyan = "#94e2d5";
          white = "#bac2de";
        };
        bright = {
          black = "#585b70";
          red = "#f7aec2";
          green = "#c2ecbf";
          yellow = "#fcd682";
          blue = "#aeccfc";
          magenta = "#cba6f7";
          cyan = "#b1eae1";
          white = "#a6adc8";
        };
        indexed_colors = [
          {
            index = 16;
            color = "#fab387";
          }
          {
            index = 17;
            color = "#f5e0dc";
          }
        ];
      };

      # Conservar Ctrl+Tab / Ctrl+Shift+Tab para los espacios de herdr.
      # Secuencias xterm modifyOtherKeys; HM las escribe como escapes TOML.
      keyboard.bindings = [
        {
          key = "Tab";
          mods = "Control";
          chars = "\\u001b[27;5;9~";
        }
        {
          key = "Tab";
          mods = "Control|Shift";
          chars = "\\u001b[27;6;9~";
        }
      ];
    };
  };
}
