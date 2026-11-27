{ config, pkgs, ... }:

{
  home.sessionVariables.TERMINAL = "alacritty";
  systemd.user.sessionVariables.TERMINAL = "alacritty";

  programs.alacritty = {
    enable = true;
    settings = {
      general = {
        working_directory = config.home.homeDirectory;
        import = [ "${config.xdg.configHome}/alacritty/dank-theme.toml" ];
        live_config_reload = true;
      };
      terminal.shell.program = "${pkgs.fish}/bin/fish";

      font = {
        normal.family = "JetBrainsMono Nerd Font";
        size = 11;
      };

      window = {
        decorations = "None";
        opacity = 0.95;
      };

      # DMS mantiene dank-theme.toml con el tema y la paleta ANSI actuales.
      # No fijar colores aquí: tendrían prioridad sobre el archivo importado.
      colors.transparent_background_colors = false;

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
