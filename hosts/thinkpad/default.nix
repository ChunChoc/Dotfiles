{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../../lib/options.nix
      ../../modules/core/bootloader.nix
      ../../modules/core/system.nix
      ../../modules/core/user.nix
      ../../modules/desktop.nix
      ../../modules/features/development.nix
      ../../modules/features/localsend.nix
    ];

  # --- ACTIVAR FEATURES ---
  myFeatures = {
    development = true;
    virtualization = false;
    localsend = true;
    gaming = false;
  };

  # Nombre del hostname
  networking.hostName = "thinkpad";

  # T480 Synaptics touchpads can fail IRQ setup on the RMI/SMBus path.
  boot.kernelParams = [ "psmouse.synaptics_intertouch=0" ];

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Use the desktop-provided SSH agent for this host.
  services.gnome.gcr-ssh-agent.enable = true;

  # Firewall base
  networking.firewall.enable = true;

  # Estado del sistema
  system.stateVersion = "25.11";

}
