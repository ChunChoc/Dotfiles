{ pkgs, ... }:

let
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
  programs.niri.enable = true;
  programs.dms-shell.enable = true;

  services.displayManager.dms-greeter = {
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
    configHome = "/home/chunchoc";
  };

  services.displayManager = {
    defaultSession = "niri-dms";
    sessionPackages = [ niriDmsSessionPackage ];
  };

  systemd.services.greetd.environment = {
    XCURSOR_PATH = "${pkgs.bibata-cursors}/share/icons";
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };

  # Force Electron/Ozone apps from Nixpkgs to use native Wayland when available.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Unlock the GNOME keyring with the password entered on the TTY login prompt.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # Removable drive integration for Nautilus in the minimal Niri session.
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
  };

  # Impresión. También registra cups-pk-helper en D-Bus/Polkit para DMS.
  services.printing.enable = true;

  # Estado de batería para DMS y otras shells/servicios de escritorio.
  services.upower.enable = true;

  # Bloquea al cerrar la tapa y suspende 5 minutos despues si sigue cerrada.
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
        ${pkgs.systemd}/bin/systemd-run --quiet --unit="$delayed_unit" --on-active=5m --collect ${pkgs.runtimeShell} -c '
          for lid_state in /proc/acpi/button/lid/*/state; do
            if ${pkgs.gnugrep}/bin/grep -q closed "$lid_state"; then
              ${pkgs.systemd}/bin/systemctl suspend
              exit 0
            fi
          done
        '
      fi
    '';
  };
}
