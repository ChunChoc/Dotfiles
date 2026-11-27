{
  config,
  pkgs,
  ...
}:

{
  home.packages = [ pkgs.herdr ];

  xdg.configFile."herdr/config.toml".source = ../dotfiles/herdr/config.toml;

  # Herdr >= 0.9.5 consulta la paleta con SIGWINCH, incluso sin cambiar el
  # tamaño. No reiniciar el servidor ni las sesiones.
  systemd.user.paths.herdr-terminal-theme = {
    Unit.Description = "Watch DMS terminal colors for Herdr";
    Path = {
      PathChanged = "${config.xdg.configHome}/alacritty/dank-theme.toml";
      Unit = "herdr-terminal-theme.service";
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.herdr-terminal-theme = {
    Unit.Description = "Refresh Herdr from the terminal palette";
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "herdr-refresh-terminal-theme" ''
        set -eu
        # Dar margen a la recarga en caliente de Alacritty antes de consultar.
        ${pkgs.coreutils}/bin/sleep 0.5
        for pid in $(${pkgs.procps}/bin/pgrep -u "$UID" -x herdr || true); do
          # Solo clientes adjuntos a un terminal; el servidor usa /dev/null.
          case "$(${pkgs.coreutils}/bin/readlink "/proc/$pid/fd/0" || true)" in
            /dev/pts/*) kill -WINCH "$pid" 2>/dev/null || true ;;
          esac
        done
      '';
    };
  };
}
