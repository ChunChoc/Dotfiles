{ pkgs, ... }:

{
  # Lazygit con la paleta ANSI del terminal y delta como pager para
  # tener resaltado de sintaxis en los diffs. Se usa tanto standalone
  # como embebido en Neovim (<leader>gg).
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        nerdFontsVersion = "3";
        theme = {
          activeBorderColor = [
            "magenta"
            "bold"
          ];
          inactiveBorderColor = [ "default" ];
          optionsTextColor = [ "blue" ];
          selectedLineBgColor = [
            "default"
            "reverse"
          ];
          cherryPickedCommitBgColor = [ "blue" ];
          cherryPickedCommitFgColor = [ "black" ];
          unstagedChangesColor = [ "red" ];
          defaultFgColor = [ "default" ];
          searchingActiveBorderColor = [ "yellow" ];
          # Antes gui.authorColors; lazygit 0.66 lo pasó a gui.theme.
          authorColors."*" = "cyan";
        };
      };

      # Esquema de lazygit >= 0.64: lista git.diffRenderers con la clave
      # `command` (antes git.pagers con `pager`, y antes git.paging).
      # Importante mantenerlo en el esquema vigente: el config.yml es un
      # symlink de solo lectura a la store y lazygit no puede migrarlo solo.
      git.diffRenderers = [
        {
          colorArg = "always";
          command = "${pkgs.delta}/bin/delta --paging=never --syntax-theme=ansi --minus-style='syntax normal' --plus-style='syntax normal' --minus-emph-style='red bold normal' --plus-emph-style='green bold normal'";
        }
      ];
    };
  };
}
