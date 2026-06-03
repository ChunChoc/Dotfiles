{ ... }:
{
  # Niri y DMS
  programs.niri.enable = true;
  programs.dms-shell.enable = true;

  # Unlock the GNOME keyring with the password entered on the TTY login prompt.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

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
}
