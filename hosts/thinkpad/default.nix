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

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Firewall base
  networking.firewall.enable = true;

  # Estado del sistema
  system.stateVersion = "25.11";

}
