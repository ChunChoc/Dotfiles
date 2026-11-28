{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.xdg) cacheHome configHome;
  directory = "${configHome}/lazygit";
  # Delta lee $XDG_CACHE_HOME/bat. Usar un caché propio para no afectar a bat.
  cache = "${cacheHome}/lazygit/delta-${pkgs.bat.version}";
  delta = lib.getExe pkgs.delta;
  refresh = pkgs.writeShellApplication {
    name = "dms-lazygit-theme";
    runtimeInputs = [
      pkgs.neovim
      pkgs.bat
      pkgs.jq
      pkgs.coreutils
      pkgs.diffutils
    ];
    text = ''
      config_file=${lib.escapeShellArg "${directory}/config.yml"}
      base=${lib.escapeShellArg "${directory}/base.json"}
      cache=${lib.escapeShellArg cache}
      if [[ ! -e $config_file ]]; then
        install -m 600 "$base" "$config_file"
      fi
      rendered=$(
        XDG_CACHE_HOME=${lib.escapeShellArg cacheHome} \
          XDG_CONFIG_HOME=${lib.escapeShellArg configHome} \
          nvim --headless -u NONE -n -i NONE -l ${../dotfiles/dms/lazygit-theme.lua} \
          ${../dotfiles/nvim} "$base" "$cache" ${delta}
      )
      if [[ -z $rendered ]]; then
        exit 0  # Conservar el último tema válido si todavía no hay paleta.
      fi
      syntax_theme=$(jq -er '.syntax' <<< "$rendered")
      if [[ ! -s $cache/bat/themes.bin || ! -s $cache/bat/syntaxes.bin || ! -s $cache/bat/metadata.yaml ]] ||
        ! cmp -s - "$cache/dms-lazy.tmTheme" <<< "$syntax_theme"; then
        mkdir -p "$cache/bat"
        build=$(mktemp -d "$cache/build.XXXXXX")
        trap 'rm -r -- "$build"' EXIT
        mkdir "$build/themes"
        printf '%s\n' "$syntax_theme" > "$build/themes/dms-lazy.tmTheme"
        BAT_CONFIG_DIR="$build" BAT_CACHE_PATH="$build/bat" bat cache --build
        # Los lectores conservan el último tema completo hasta el rename.
        for asset in syntaxes.bin metadata.yaml themes.bin; do
          mv -T "$build/bat/$asset" "$cache/bat/$asset"
        done
        mv -T "$build/themes/dms-lazy.tmTheme" "$cache/dms-lazy.tmTheme"
      fi
      settings=$(jq -S '.config' <<< "$rendered")
      if ! cmp -s - "$config_file" <<< "$settings"; then
        tmp=$(mktemp "$config_file.XXXXXX")
        printf '%s\n' "$settings" > "$tmp"
        mv -T "$tmp" "$config_file"
      fi
    '';
  };
in
{
  programs.lazygit.enable = true;
  # Esta base también sirve antes del primer login gráfico. El servicio
  # escribe config.yml tras aplicar los colores RGB.
  xdg.configFile."lazygit/base.json".text = builtins.toJSON {
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
        authorColors."*" = "cyan";
      };
    };

    git.diffRenderers = [
      {
        colorArg = "always";
        command = "${delta} --paging=never --syntax-theme=ansi --minus-style='syntax normal' --plus-style='syntax normal' --minus-emph-style='red bold normal' --plus-emph-style='green bold normal'";
      }
    ];
  };
  systemd.user.services.dms-client-themes.Service.ExecStartPost = [ (lib.getExe refresh) ];
}
