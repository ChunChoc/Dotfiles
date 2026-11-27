{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  inherit (config.xdg) cacheHome configHome;
  palette = "${cacheHome}/dms/dms-colors.json";
  claudeDir = lib.optionalString osConfig.myFeatures.development "${config.home.homeDirectory}/.claude/themes";
  refresh = pkgs.writeShellApplication {
    name = "dms-client-themes";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.diffutils
      pkgs.jq
      pkgs.procps
      pkgs.rmpc
    ];
    text = builtins.readFile ../dotfiles/dms/refresh-client-themes.sh;
  };
  command = "${lib.getExe refresh} ${lib.escapeShellArgs [ palette configHome claudeDir ]}";
  systemctl = lib.getExe' pkgs.systemd "systemctl";
in
{
  # DMS publica una paleta por wallpaper y modo. systemd vuelve a generar
  # los temas RGB solo cuando cambia ese archivo; no hay un daemon adicional.
  systemd.user.paths.dms-client-themes = {
    Unit.Description = "Watch the DMS palette for client themes";
    Path.PathChanged = palette;
    Install.WantedBy = [ "default.target" ];
  };
  systemd.user.services.dms-client-themes = {
    Unit.Description = "Refresh RMPC, Cava and Claude Code themes from DMS";
    Service = {
      Type = "oneshot";
      ExecStart = command;
    };
    Install.WantedBy = [ "default.target" ];
  };
  home.activation.dmsClientThemes = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
    if ${systemctl} --user is-active --quiet dms-client-themes.path; then
      run ${systemctl} --user start dms-client-themes.service
    fi
  '';

  xdg.configFile."rmpc/dms-theme.ron.in".source = ../dotfiles/rmpc/themes/dms.ron.in;
}
