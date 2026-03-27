{ config, lib, pkgs, monitorSettings, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../lib/options.nix
      ../../modules/core/bootloader.nix
      ../../modules/core/system.nix
      ../../modules/core/user.nix
      ../../modules/desktop.nix
      ../../modules/features/virtualization.nix
      ../../modules/features/localsend.nix
      ../../modules/features/development.nix
      ../../modules/features/gaming.nix
    ];

  # --- ACTIVAR FEATURES ---
  myFeatures = {
    development = true;
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
