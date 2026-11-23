{
  config,
  lib,
  pkgs,
  externalOutputs,
  monitorSettings,
  ...
}:

let
  primaryLogicalWidth = builtins.ceil (monitorSettings.width / monitorSettings.scale);
  renderExternalOutput = output: ''
    output "${output.name}" {
        ${if output ? mode then ''mode "${output.mode}"'' else ""}
        scale ${toString (output.scale or 1)}
        transform "${output.transform or "normal"}"
        position x=${toString (output.positionX or primaryLogicalWidth)} y=${
          toString (output.positionY or 0)
        }
    }
  '';
  initialOutputs = pkgs.writeText "dms-initial-outputs.kdl" ''
    output "${monitorSettings.name}" {
        mode "${toString monitorSettings.width}x${toString monitorSettings.height}@${toString monitorSettings.refreshRate}"
        scale ${toString monitorSettings.scale}
        transform "normal"
        position x=0 y=0
    }
    ${builtins.concatStringsSep "\n" (map renderExternalOutput externalOutputs)}
  '';

  # Son valores iniciales, no archivos que Home Manager mantenga enlazados.
  # Los cambios de barra, tema, pantallas, layout y atajos pertenecen a DMS.
  initialConfig = {
    "DankMaterialShell/settings.json" = ../dotfiles/DankMaterialShell/settings.json;
    "niri/dms/alttab.kdl" = ../dotfiles/niri/dms/alttab.kdl;
    "niri/dms/binds.kdl" = ../dotfiles/niri/dms/binds.kdl;
    "niri/dms/cursor.kdl" = ../dotfiles/niri/dms/cursor.kdl;
    "niri/dms/effects.kdl" = ../dotfiles/niri/dms/effects.kdl;
    "niri/dms/layout.kdl" = ../dotfiles/niri/dms/layout.kdl;
    "niri/dms/windowrules.kdl" = ../dotfiles/niri/dms/windowrules.kdl;
    "niri/dms/wpblur.kdl" = ../dotfiles/niri/dms/wpblur.kdl;
  };

  # El estado existente no se toca. Estos defaults solo sirven para una
  # primera instalación; no hay servicios que los reimpongan al iniciar sesión.
  initialSession = pkgs.writeText "dms-initial-session.json" (
    builtins.toJSON {
      wallpaperPath = "${config.home.homeDirectory}/Pictures/Wallpapers/nix-magenta-blue-1920x1080.png";
      isLightMode = false;
      wallpaperTransition = "disc";
      includedTransitions = [ "disc" ];
      wallpaperCyclingInterval = 3600;
      nightModeEnabled = true;
      nightModeTemperature = 3700;
      nightModeHighTemperature = 6500;
      nightModeAutoEnabled = true;
      nightModeAutoMode = "time";
      nightModeStartHour = 18;
      nightModeStartMinute = 0;
      nightModeEndHour = 6;
      nightModeEndMinute = 0;
      nightModeUseIPLocation = false;
    }
  );

  seedMutableConfig = pkgs.writeShellScript "dms-seed-mutable-config" ''
    set -eu
    export PATH="${lib.makeBinPath [ pkgs.coreutils ]}"
    config_home="$1"
    state_home="$2"

    seed_file() {
      local target="$1" initial="$2" source resolved tmp
      if [ -L "$target" ]; then
        resolved="$(readlink -f "$target" || true)"
        case "$resolved" in
          /nix/store/*)
            # Migración: conservar el contenido activo, no la nueva plantilla.
            source="$target"
            ;;
          *)
            # Los enlaces personales fuera de la store siguen siendo suyos.
            return 0
            ;;
        esac
      elif [ -e "$target" ]; then
        return 0
      else
        source="$initial"
      fi

      mkdir -p "$(dirname "$target")"
      tmp="$(mktemp "$target.XXXXXX")"
      if install -m 0644 "$source" "$tmp" && mv -T "$tmp" "$target"; then
        return 0
      else
        rm -f "$tmp"
        return 1
      fi
    }

    seed_outputs() {
      local target="$config_home/niri/dms/outputs.kdl"
      local legacy="$config_home/niri/monitors.kdl" resolved tmp
      if [ -L "$target" ] && [ -r "$legacy" ]; then
        resolved="$(readlink -f "$target" || true)"
        case "$resolved" in
          /nix/store/*)
            # Antes había dos archivos: panel interno y pantallas externas.
            # Consolidarlos una vez evita que el panel fijo anule la GUI.
            tmp="$(mktemp "$target.XXXXXX")"
            if cat "$legacy" "$target" > "$tmp" \
              && chmod 0644 "$tmp" && mv -T "$tmp" "$target"; then
              return 0
            else
              rm -f "$tmp"
              return 1
            fi
            ;;
        esac
      fi
      seed_file "$target" "${initialOutputs}"
    }

    seed_outputs
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: source:
        ''seed_file "$config_home"/${lib.escapeShellArg name} ${lib.escapeShellArg "${source}"}''
      ) initialConfig
    )}
    seed_file "$state_home/DankMaterialShell/session.json" "${initialSession}"
  '';
in
{
  # Hay que convertir los enlaces antiguos ANTES de que linkGeneration intente
  # retirarlos. Al ser archivos normales, su limpieza ya no los elimina.
  # `run` respeta el dry-run de Home Manager.
  home.activation.seedDmsMutableConfig =
    lib.hm.dag.entryBetween
      [ "linkGeneration" ]
      [
        "writeBoundary"
      ]
      ''run "${seedMutableConfig}" "${config.xdg.configHome}" "${config.xdg.stateHome}"'';
}
