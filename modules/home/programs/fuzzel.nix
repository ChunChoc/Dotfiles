{ pkgs, ... }:

{
  # Fuzzel (Lanzador)
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "${pkgs.alacritty}/bin/alacritty";
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

      # Catppuccin Mocha
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
}
