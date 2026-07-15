{ pkgs, ... }:

{
  # Lazygit con tema Catppuccin Mocha (mauve) y delta como pager para
  # tener resaltado de sintaxis en los diffs. Se usa tanto standalone
  # como embebido en Neovim (<leader>gg).
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        nerdFontsVersion = "3";
        theme = {
          activeBorderColor = [ "#cba6f7" "bold" ];
          inactiveBorderColor = [ "#a6adc8" ];
          optionsTextColor = [ "#89b4fa" ];
          selectedLineBgColor = [ "#313244" ];
          cherryPickedCommitBgColor = [ "#45475a" ];
          cherryPickedCommitFgColor = [ "#cba6f7" ];
          unstagedChangesColor = [ "#f38ba8" ];
          defaultFgColor = [ "#cdd6f4" ];
          searchingActiveBorderColor = [ "#f9e2af" ];
        };
        authorColors."*" = "#b4befe";
      };

      git.paging = {
        colorArg = "always";
        pager = "${pkgs.delta}/bin/delta --dark --paging=never";
      };
    };
  };
}
