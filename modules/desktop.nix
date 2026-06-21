{ pkgs, ... }:
{
  # Niri y DMS
  programs.niri.enable = true;
  programs.dms-shell.enable = true;

  # Force Electron/Ozone apps from Nixpkgs to use native Wayland when available.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Unlock the GNOME keyring with the password entered on the TTY login prompt.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # Removable drive integration for Nautilus in the minimal Niri session.
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
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
