{ pkgs, ... }:

let
  # Arranque de Niri desde una TTY: importa el entorno de la sesión al user
  # manager de systemd antes de lanzar el compositor. Es el fallback manual
  # si el greeter (greetd + dms-greeter en modules/desktop.nix) está apagado;
  # con el greeter activo greetd ocupa tty1 y este exec nunca se dispara.
  niriSessionTTY = pkgs.writeShellScript "niri-session-tty" ''
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
in

{
  programs.fish.interactiveShellInit = ''
    if test (tty) = /dev/tty1; and not set -q WAYLAND_DISPLAY; and not set -q DISPLAY; and not set -q NIRI_SOCKET
      exec ${niriSessionTTY}
    end
  '';
}
