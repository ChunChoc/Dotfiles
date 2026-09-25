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
      | .wallpaperCyclingInterval = 3600
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
  # Acento de DMS según el wallpaper. El tema `custom` es Catppuccin
  # (themes/catppuccin/theme.json, con los 14 acentos oficiales); este script
  # saca el color fuente del wallpaper con matugen, elige el acento Catppuccin
  # de tono más cercano y escribe una copia del tema con ese acento como
  # `variants.defaults`. `customThemeFile` en settings.json apunta a esa copia
  # y DMS la vigila (FileView watchChanges), así que recarga sin reiniciar.
  # Solo cambia el acento: superficies, texto y demás siguen siendo Mocha.
  catppuccinThemeJson = ./dotfiles/DankMaterialShell/themes/catppuccin/theme.json;
  applyWallpaperAccent = pkgs.writeShellScript "dms-wallpaper-accent" ''
    set -eu

    jq="${pkgs.jq}/bin/jq"
    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/DankMaterialShell"
    session_json="$state_dir/session.json"
    theme_out="$state_dir/catppuccin-theme.json"
    stamp="$state_dir/catppuccin-theme.wallpaper"

    wallpaper=""
    if [ -r "$session_json" ]; then
      wallpaper="$("$jq" -r '
        if (.perModeWallpaper == true and .isLightMode == true and (.wallpaperPathLight // "") != "") then
          .wallpaperPathLight
        elif (.perModeWallpaper == true and .isLightMode == false and (.wallpaperPathDark // "") != "") then
          .wallpaperPathDark
        else
          .wallpaperPath // ""
        end
      ' "$session_json" 2>/dev/null || true)"
    fi
    [ "$wallpaper" = "null" ] && wallpaper=""

    # Idempotente: session.json se reescribe por muchas cosas, no solo por el
    # wallpaper. Sin copia previa del tema hay que generarla igual (primer
    # arranque), aunque sea con el acento por defecto.
    if [ -s "$theme_out" ] && [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$wallpaper" ]; then
      exit 0
    fi

    source=""
    if [[ "$wallpaper" == \#* ]]; then
      source="$wallpaper"
    elif [ -f "$wallpaper" ]; then
      # `--prefer saturation`: entre varios candidatos, el más saturado es el
      # que sirve de acento. Sin `--prefer` matugen pide input interactivo.
      source="$(${pkgs.matugen}/bin/matugen image "$wallpaper" --dry-run --json hex --prefer saturation 2>/dev/null \
        | "$jq" -r '.colors.source_color.dark.color // ""' || true)"
    fi

    # Acento Catppuccin más cercano por tono (HSL). Con saturación muy baja el
    # tono no significa nada: vuelve a mauve, el acento histórico del sistema.
    accent="mauve"
    if [[ "$source" =~ ^#[0-9a-fA-F]{6}$ ]]; then
      accent="$(${pkgs.gawk}/bin/gawk -v src="$source" '
        function hsl(hex,   r, g, b, mx, mn, d) {
          r = strtonum("0x" substr(hex, 2, 2)) / 255
          g = strtonum("0x" substr(hex, 4, 2)) / 255
          b = strtonum("0x" substr(hex, 6, 2)) / 255
          mx = r; if (g > mx) mx = g; if (b > mx) mx = b
          mn = r; if (g < mn) mn = g; if (b < mn) mn = b
          d = mx - mn
          L = (mx + mn) / 2
          S = d == 0 ? 0 : d / (1 - (2 * L - 1 < 0 ? -(2 * L - 1) : 2 * L - 1))
          if (d == 0) H = 0
          else if (mx == r) H = 60 * (((g - b) / d) % 6)
          else if (mx == g) H = 60 * ((b - r) / d + 2)
          else H = 60 * ((r - g) / d + 4)
          if (H < 0) H += 360
        }
        BEGIN {
          n = split("rosewater:#f5e0dc flamingo:#f2cdcd pink:#f5c2e7 mauve:#cba6f7 red:#f38ba8 maroon:#eba0ac peach:#fab387 yellow:#f9e2af green:#a6e3a1 teal:#94e2d5 sky:#89dceb sapphire:#74c7ec blue:#89b4fa lavender:#b4befe", acc, " ")
          hsl(src); sh = H
          if (S < 0.08) { print "mauve"; exit }
          best = "mauve"; bestd = 999
          for (i = 1; i <= n; i++) {
            split(acc[i], kv, ":"); hsl(kv[2])
            d = H - sh; if (d < 0) d = -d; if (d > 180) d = 360 - d
            if (d < bestd) { bestd = d; best = kv[1] }
          }
          print best
        }')"
    fi

    mkdir -p "$state_dir"
    tmp="$(mktemp "$state_dir/catppuccin-theme.XXXXXX")"
    "$jq" --arg a "$accent" \
      '.variants.defaults.dark.accent = $a | .variants.defaults.light.accent = $a' \
      "${catppuccinThemeJson}" > "$tmp"
    # Si el acento no cambió (el wallpaper nuevo cae en el mismo), no se toca el
    # archivo: DMS lo vigila y cada escritura le hace regenerar el tema entero.
    if cmp -s "$tmp" "$theme_out"; then
      rm -f "$tmp"
    else
      mv "$tmp" "$theme_out"
    fi
    printf '%s\n' "$wallpaper" > "$stamp"
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


  # Corre antes de DMS para que la copia del tema exista al arrancar, y cada
  # vez que cambia session.json (rotado horario, `dms ipc wallpaper set`…).
  systemd.user.services.dms-wallpaper-accent = {
    Unit = {
      Description = "Pick the DMS Catppuccin accent from the current wallpaper";
      # Sin límite de arranques. El de systemd (5 en 10 s) se agota cambiando
      # de wallpaper seguido con Mod+W / Mod+Shift+W: al 6.º el servicio
      # falla con start-limit-hit, arrastra al .path y el acento se queda
      # congelado hasta reiniciar la sesión. Quitarlo es seguro: el script es
      # idempotente (sale al instante si el wallpaper no cambió) y systemd
      # nunca corre dos a la vez, fusiona los disparos en cola.
      StartLimitIntervalSec = 0;
      Before = [ "dms.service" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${applyWallpaperAccent}";
      # Corre en el mismo instante que la transición del wallpaper; a prioridad
      # mínima para que matugen (PNG 4K) no le robe CPU al render de DMS.
      Nice = 19;
      CPUSchedulingPolicy = "idle";
      IOSchedulingClass = "idle";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.paths.dms-wallpaper-accent = {
    Unit = {
      Description = "Watch the DMS session file for wallpaper changes";
      PartOf = [ "graphical-session.target" ];
    };

    Path = {
      PathModified = "%S/DankMaterialShell/session.json";
      Unit = "dms-wallpaper-accent.service";
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
