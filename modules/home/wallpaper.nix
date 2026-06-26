{ pkgs, ... }:

let
  defaultWallpaperName = "nix-magenta-blue-1920x1080.png";
  defaultWallpaperPath = "%h/Pictures/Wallpapers/${defaultWallpaperName}";
  applyDmsDefaults = pkgs.writeShellScript "dms-session-defaults" ''
    set -eu

    default_wallpaper="$1"
    dms="${pkgs.dms-shell}/bin/dms"

    current_wallpaper=""
    for _ in 1 2 3 4 5; do
      if current_wallpaper="$("$dms" ipc wallpaper get 2>/dev/null)"; then
        break
      fi

      sleep 1
    done

    if [ -z "$current_wallpaper" ] || [ ! -f "$current_wallpaper" ]; then
      "$dms" ipc wallpaper set "$default_wallpaper"
    fi

    "$dms" ipc theme dark >/dev/null 2>&1 || true
  '';
in

{
  home.file."Pictures/Wallpapers/${defaultWallpaperName}".source =
    ../../wallpaper/nix-magenta-blue-1920x1080.png;

  systemd.user.services.dms-session-defaults = {
    Unit = {
      Description = "Apply DMS session defaults";
      After = [ "graphical-session.target" "dms.service" ];
      Wants = [ "dms.service" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${applyDmsDefaults} ${defaultWallpaperPath}";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
