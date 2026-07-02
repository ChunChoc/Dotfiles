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
    office = true;
    virtualization = false;
    localsend = true;
    gaming = true;
  };

  # Nombre del hostname
  networking.hostName = "aorus";

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;
  # MAC WiFi aleatoria por conexión: evita rastreo entre redes.
  networking.networkmanager.wifi.macAddress = "random";

  # Firewall base
  networking.firewall.enable = true;

  # Estado del sistema
  system.stateVersion = "25.11";

}
