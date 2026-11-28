{
  config,
  lib,
  pkgs,
  ...
}:

let
  greeterCursorTheme = "Bibata-Modern-Classic";
  greeterCursorSize = "24";
  greeterCursorPath = "${pkgs.bibata-cursors}/share/icons";

  dmsGreeterCfg = config.services.displayManager.dux-greeter;
  dmsGreeterSourceHome = config.users.users.chunchoc.home;
  dmsGreeterSnapshotDir = "dms-greeter-snapshot";
  dmsGreeterSessionFile = "/run/${dmsGreeterSnapshotDir}/session.json";
  dmsGreeterCompositorConfig = pkgs.writeText "dmsgreeter-compositor-config" dmsGreeterCfg.compositor.customConfig;
  dmsGreeterStart = pkgs.writeShellScriptBin "dms-greeter-start-with-cursor" ''
    export PATH="$PATH:${
      lib.makeBinPath [
        dmsGreeterCfg.quickshell.package
        pkgs.glib # gdbus: lo usa el greeter para fprintd y portales
        config.programs.${dmsGreeterCfg.compositor.name}.package
      ]
    }"

    exec ${pkgs.coreutils}/bin/env \
      XCURSOR_PATH=${greeterCursorPath} \
      XCURSOR_THEME=${greeterCursorTheme} \
      XCURSOR_SIZE=${greeterCursorSize} \
      ${dmsGreeterCfg.package}/bin/dms-greeter \
      --cache-dir /var/lib/dms-greeter \
      --command ${dmsGreeterCfg.compositor.name} \
      -C ${dmsGreeterCompositorConfig}
  '';

  niriDmsSession = pkgs.writeShellScriptBin "niri-dms-session" ''
        if systemctl --user -q is-active niri.service; then
          echo 'A niri session is already running.'
          exit 1
        fi

        systemctl --user reset-failed

        env_vars=""
        while IFS='=' read -r name _; do
          case "$name" in
            "" | [0-9]* | *[!A-Za-z0-9_]* ) continue ;;
          esac
          env_vars="$env_vars $name"
        done <<EOF
    $(env)
    EOF

        if [ -n "$env_vars" ]; then
          systemctl --user import-environment $env_vars
        fi

        if [ -n "$env_vars" ] && command -v dbus-update-activation-environment >/dev/null 2>&1; then
          dbus-update-activation-environment $env_vars
        fi

        systemctl --user --wait start niri.service
        systemctl --user start --job-mode=replace-irreversibly niri-shutdown.target
        systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP NIRI_SOCKET
  '';

  niriDmsSessionPackage = pkgs.symlinkJoin {
    name = "niri-dms-session";
    paths = [ niriDmsSession ];
    passthru.providedSessions = [ "niri-dms" ];
    postBuild = ''
            mkdir -p $out/share/wayland-sessions
            cat > $out/share/wayland-sessions/niri-dms.desktop <<EOF
      [Desktop Entry]
      Name=Niri + DMS
      Comment=Niri session with explicit environment import
      Exec=${niriDmsSession}/bin/niri-dms-session
      Type=Application
      DesktopNames=niri
      EOF
    '';
  };
in

{
  # Niri y DMS
  programs.niri = {
    enable = true;
    useNautilus = false;
  };
  # El servicio mantiene la interfaz cargada, oculta y sin ventanas al iniciar
  # sesión. --keep-running oculta la última ventana en vez de salir: Mod+E
  # reutiliza la instancia, sin el arranque en frío ni keepalives artificiales.
  # GNOME se conserva para los demás portales (p. ej. compartir pantalla),
  # pero los diálogos abrir/guardar los atiende Dux Files.
  programs.dux-files = {
    enable = true;
    systemd.enable = true;
    portal.enable = true;
  };
  # Al desactivar el gestor de GNOME, niri propone GTK como selector.
  # Mantener explícitamente Dux por encima de ese fallback.
  xdg.portal.config.niri."org.freedesktop.impl.portal.FileChooser" = lib.mkForce [ "dfiles" ];
  # Conservar el PATH de la sesión para xdg-open, terminal y apps del usuario.
  # El PATH mínimo que NixOS añade a los units taparía el entorno importado.
  systemd.user.services.dfiles.enableDefaultPath = false;
  programs.dux-shell = {
    enable = true;

    # M3 Expressive nativo de DMS 2.x, sin parches locales de geometría,
    # superficies ni muelles. Las preferencias siguen siendo editables en la GUI.
    package = pkgs.dux-shell;
  };

  # Planes de energía (ahorro / balanceado / rendimiento) del selector de DMS.
  # Antes llegaba implícito: el módulo dms-shell de nixpkgs lo activaba con
  # mkDefault, y en el nixpkgs del 2026-09-22 dejó de hacerlo. DMS se quedó sin
  # daemon con el que hablar, de ahí el error al cambiar de plan. PPD recuerda
  # el último plan elegido y arranca en balanceado la primera vez.
  services.power-profiles-daemon.enable = true;

  services.displayManager.dux-greeter = {
    enable = true;
    compositor = {
      name = "niri";
      customConfig = ''
        hotkey-overlay {
          skip-at-startup
        }

        environment {
          DMS_RUN_GREETER "1"
          XCURSOR_THEME "Bibata-Modern-Classic"
          XCURSOR_SIZE "24"
        }

        cursor {
          xcursor-theme "Bibata-Modern-Classic"
          xcursor-size 24
        }

        gestures {
          hot-corners {
            off
          }
        }

        layout {
          background-color "#000000"
        }
      '';
    };
    configFiles = [
      "${dmsGreeterSourceHome}/.config/dms/settings.json"
      dmsGreeterSessionFile
      "${dmsGreeterSourceHome}/.cache/dms/dms-colors.json"
    ];
  };

  systemd.services.greetd = {
    serviceConfig = {
      RuntimeDirectory = dmsGreeterSnapshotDir;
      RuntimeDirectoryMode = "0700";
    };

    # El greeter sólo muestra imágenes. Antes de que NixOS copie los fondos,
    # sustituir cada vídeo por el fotograma que genera DMS para ese mismo vídeo.
    preStart = lib.mkBefore ''
      ${lib.getExe pkgs.python3} - ${
        lib.escapeShellArgs [
          dmsGreeterSourceHome
          dmsGreeterSessionFile
          "${../wallpaper/nix-magenta-blue-1920x1080.png}"
        ]
      } <<'PY'
      import hashlib
      import json
      import sys
      from pathlib import Path

      home, snapshot, fallback = map(Path, sys.argv[1:])
      posters = home / ".cache/dms/video-wallpaper"
      video_extensions = {".mp4", ".webm", ".mkv", ".mov", ".m4v", ".avi"}

      def wallpaper_image(value):
          if not isinstance(value, str) or Path(value).suffix.lower() not in video_extensions:
              return value
          digest = hashlib.md5(value.encode("utf-8")).hexdigest()
          poster = posters / (digest + ".jpg")
          return str(poster if poster.is_file() else fallback)

      try:
          session = json.loads((home / ".local/state/dms/session.json").read_text(encoding="utf-8"))
      except (OSError, ValueError):
          session = {}
      if not isinstance(session, dict):
          session = {}

      session.setdefault("wallpaperPath", str(fallback))
      for suffix in ("", "Light", "Dark"):
          wallpaper_key = "wallpaperPath" + suffix
          if wallpaper_key in session:
              session[wallpaper_key] = wallpaper_image(session[wallpaper_key])

          monitors = session.get("monitorWallpapers" + suffix)
          if isinstance(monitors, dict):
              for monitor, wallpaper in monitors.items():
                  monitors[monitor] = wallpaper_image(wallpaper)

      snapshot.write_text(json.dumps(session), encoding="utf-8")
      PY
    '';
  };

  services.displayManager = {
    defaultSession = "niri-dms";
    sessionPackages = [ niriDmsSessionPackage ];
  };

  services.greetd.settings.default_session.command =
    lib.mkForce "${dmsGreeterStart}/bin/dms-greeter-start-with-cursor";

  systemd.services.greetd.environment = {
    XCURSOR_PATH = greeterCursorPath;
    XCURSOR_THEME = greeterCursorTheme;
    XCURSOR_SIZE = greeterCursorSize;
  };

  # Force Electron/Ozone apps from Nixpkgs to use native Wayland when available.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Unlock the GNOME keyring with the password entered on the TTY login prompt.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # Almacenamiento extraíble. udisks2 hace el montaje y gvfs lo expone a Dux
  # Files y las apps GTK, junto con papelera y ubicaciones smb:// y sftp://.
  #
  # Sin gvfs siempre queda la vía manual: `udisksctl mount -b /dev/sdX`.
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    bibata-cursors
    exfatprogs
    ntfs3g
    usbutils
  ];

  # Audio (Pipewire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # El timbre de X11 conecta a DISPLAY al arrancar PipeWire y adelanta
    # el inicio de Xwayland, incluso si todas las aplicaciones son Wayland.
    extraConfig.pipewire."10-disable-x11-bell"."context.properties"."module.x11.bell" = false;

    # El grafo corre a 48 kHz (lo que quieren las llamadas y el escritorio), pero
    # la biblioteca de MPD es FLAC 16/44.1: a rate fijo cada canción pasaría por
    # un remuestreo 44.1 -> 48 innecesario. Con allowed-rates PipeWire conmuta el
    # grafo al rate nativo del stream y la reproducción sale bit-perfect hasta el
    # DAC (en los Moondrop MAY, el que trae el propio cable USB-C).
    #
    # Solo conmuta cuando no hay otro stream sonando, así que una llamada en
    # curso nunca se ve interrumpida: en ese caso gana el rate del grafo y MPD
    # es el que se remuestrea, que es exactamente el orden de prioridades que
    # queremos.
    extraConfig.pipewire."10-clock-rates" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        # Las dos familias completas (múltiplos de 44.1 y de 48). Si un archivo
        # viene a un rate que no esté aquí, o que la tarjeta no soporte, no pasa
        # nada malo: PipeWire simplemente lo remuestrea como hasta ahora.
        # El códec interno (ALC257) reporta 44100/48000/96000/192000, así que
        # 88200 y 176400 solo aplicarán a un DAC USB que sí los tenga.
        "default.clock.allowed-rates" = [
          44100
          48000
          88200
          96000
          176400
          192000
        ];
      };
    };
  };

  # La impresión (CUPS) vive en modules/features/printing.nix.

  # Estado de batería para DMS y otras shells/servicios de escritorio.
  services.upower.enable = true;

  # Bloquea al cerrar la tapa y suspende 1 minuto despues si sigue cerrada
  # (suspend-then-hibernate: si sigue suspendida 1 h, hiberna al swap cifrado).
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  services.acpid = {
    enable = true;
    lidEventCommands = ''
      delayed_unit="chunchoc-lid-close-suspend"

      lid_is_closed() {
        for lid_state in /proc/acpi/button/lid/*/state; do
          if ${pkgs.gnugrep}/bin/grep -q closed "$lid_state"; then
            return 0
          fi
        done
        return 1
      }

      ${pkgs.systemd}/bin/systemctl stop "$delayed_unit.timer" "$delayed_unit.service" >/dev/null 2>&1 || true

      if lid_is_closed; then
        ${pkgs.systemd}/bin/loginctl lock-sessions
        ${pkgs.systemd}/bin/systemd-run --quiet --unit="$delayed_unit" --on-active=1m --collect ${pkgs.runtimeShell} -c '
          for lid_state in /proc/acpi/button/lid/*/state; do
            if ${pkgs.gnugrep}/bin/grep -q closed "$lid_state"; then
              ${pkgs.systemd}/bin/systemctl suspend-then-hibernate
              exit 0
            fi
          done
        '
      fi
    '';
  };
}
