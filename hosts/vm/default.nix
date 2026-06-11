{ config, lib, pkgs, monitorSettings, ... }:

{
  imports =
    [
      # ./hardware-configuration.nix  # Generar con `nixos-generate-config` al instalar NixOS en esta máquina
    ];

  # --- ACTIVAR FEATURES ---
  myFeatures = {
    development = true;
    communication = false;
    office = false;
    virtualization = true;
    localsend = true;
    gaming = false;
  };

  # Fuerza la resolución desde el arranque del Kernel
  boot.kernelParams = [
    "video=${monitorSettings.name}:${toString monitorSettings.width}x${toString monitorSettings.height}"
  ];

  # Habilita el copy-paste entre host y VM, y el ajuste de pantalla automático
  services.spice-vdagentd.enable = true;
  services.qemuGuest.enable = true;

  # Nombre del hostname
  networking.hostName = "nixos-vm";

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Firewall base (LocalSend lo maneja el feature localsend)
  networking.firewall.enable = true;

  # Esto NO se cambia supongo
  system.stateVersion = "25.11";

}
