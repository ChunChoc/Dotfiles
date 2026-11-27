{ pkgs, ... }:

let
  defaultWallpaperName = "nix-magenta-blue-1920x1080.png";
  niriStartupWallpaper = pkgs.writeShellScript "niri-startup-wallpaper" ''
    set -eu

    session_json="''${XDG_STATE_HOME:-$HOME/.local/state}/dms/session.json"
    settings_json="''${XDG_CONFIG_HOME:-$HOME/.config}/dms/settings.json"

    dms_wallpaper_ready() {
      ${pkgs.niri}/bin/niri msg --json layers 2>/dev/null \
        | ${pkgs.jq}/bin/jq -e 'any(.[]; .namespace == "quickshell" and .layer == "Background")' >/dev/null
    }

    if dms_wallpaper_ready; then
      exit 0
    fi

    if [ ! -r "$session_json" ]; then
      exit 0
    fi

    wallpaper="$(${pkgs.jq}/bin/jq -r '
      if (.perModeWallpaper == true and .isLightMode == true and (.wallpaperPathLight // "") != "") then
        .wallpaperPathLight
      elif (.perModeWallpaper == true and .isLightMode == false and (.wallpaperPathDark // "") != "") then
        .wallpaperPathDark
      else
        .wallpaperPath // ""
      end
    ' "$session_json" 2>/dev/null || true)"

    if [ -z "$wallpaper" ] || [ "$wallpaper" = "null" ]; then
      exit 0
    fi

    mode="$(${pkgs.jq}/bin/jq -r '.wallpaperFillMode // "Fill"' "$settings_json" 2>/dev/null || printf 'Fill')"
    case "$mode" in
      Stretch) swaybg_mode="stretch" ;;
      Fit|PreserveAspectFit) swaybg_mode="fit" ;;
      Tile|TileVertically|TileHorizontally) swaybg_mode="tile" ;;
      *) swaybg_mode="fill" ;;
    esac

    if [[ "$wallpaper" == \#* ]]; then
      ${pkgs.swaybg}/bin/swaybg -c "$wallpaper" &
    elif [ -f "$wallpaper" ]; then
      ${pkgs.swaybg}/bin/swaybg -i "$wallpaper" -m "$swaybg_mode" &
    else
      exit 0
    fi

    swaybg_pid="$!"
    cleanup() {
      kill "$swaybg_pid" 2>/dev/null || true
    }
    trap cleanup EXIT INT TERM

    while kill -0 "$swaybg_pid" 2>/dev/null; do
      if dms_wallpaper_ready; then
        # Let DMS finish its wallpaper fade-in before removing the temporary
        # layer. swaybg sits underneath in the same backdrop slot, so
        # over-waiting is invisible; under-waiting is what would flicker.
        sleep 1
        exit 0
      fi
      sleep 0.1
    done
  '';
in

{
  home.file."Pictures/Wallpapers/${defaultWallpaperName}".source =
    ../../wallpaper/nix-magenta-blue-1920x1080.png;

  systemd.user.services.niri-startup-wallpaper = {
    Unit = {
      Description = "Show last DMS wallpaper while the shell starts";
      After = [ "niri.service" ];
      Before = [ "dms.service" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${niriStartupWallpaper}";
      Restart = "no";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
