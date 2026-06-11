{ config, lib, pkgs, ... }:

{
  imports =
    [
      # ./hardware-configuration.nix  # Generar con `nixos-generate-config` al instalar NixOS en esta máquina
    ];

  # --- ACTIVAR FEATURES ---
  myFeatures = {
    development = true;
    communication = true;
    virtualization = false;
    localsend = true;
    gaming = true;
  };

  # Nombre del hostname
  networking.hostName = "aorus";

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Firewall base
  networking.firewall.enable = true;

  # Estado del sistema
  system.stateVersion = "25.11";

}
