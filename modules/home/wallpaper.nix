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
  applyDmsNightModeDefaults = pkgs.writeShellScript "dms-night-mode-defaults" ''
    set -eu

    session_json="''${XDG_STATE_HOME:-$HOME/.local/state}/DankMaterialShell/session.json"
    tmp="$(mktemp)"
    cleanup() {
      rm -f "$tmp" "$tmp.input"
    }
    trap cleanup EXIT INT TERM

    mkdir -p "$(dirname "$session_json")"

    if [ -s "$session_json" ] && ${pkgs.jq}/bin/jq -e 'type == "object"' "$session_json" >/dev/null 2>&1; then
      input="$session_json"
    else
      printf '{}' > "$tmp.input"
      input="$tmp.input"
    fi

    ${pkgs.jq}/bin/jq '
      .wallpaperTransition = "disc"
      | .includedTransitions = ["disc"]
      | .nightModeEnabled = true
      | .nightModeTemperature = 3700
      | .nightModeHighTemperature = 6500
      | .nightModeAutoEnabled = true
      | .nightModeAutoMode = "time"
      | .nightModeStartHour = 18
      | .nightModeStartMinute = 0
      | .nightModeEndHour = 6
      | .nightModeEndMinute = 0
      | .nightModeUseIPLocation = false
    ' "$input" > "$tmp"

    install -m 0644 "$tmp" "$session_json"
  '';
  niriStartupWallpaper = pkgs.writeShellScript "niri-startup-wallpaper" ''
    set -eu

    session_json="''${XDG_STATE_HOME:-$HOME/.local/state}/DankMaterialShell/session.json"
    settings_json="''${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/settings.json"

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

  systemd.user.services.dms-night-mode-defaults = {
    Unit = {
      Description = "Apply DMS night mode defaults";
      Before = [ "dms.service" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${applyDmsNightModeDefaults}";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

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
