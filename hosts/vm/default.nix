{ config, lib, pkgs, monitorSettings, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/core/bootloader.nix
      ../../modules/core/system.nix
      ../../modules/core/user.nix
      ../../modules/desktop.nix
    ];

  # Fuerza la resolución desde el arranque del Kernel
  boot.kernelParams = [ 
    "video=${monitorSettings.name}:${toString monitorSettings.width}x${toString monitorSettings.height}"
  ];

  # Habilita el copy-paste entre host y VM, y el ajuste de pantalla automático
  services.spice-vdagentd.enable = true; 
  services.qemuGuest.enable = true;
  
  # Nombre del hostname
  networking.hostName = "nixos_vm";

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Virtualización (KVM/QEMU)
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true; # Para emular TPM (Windows 11)
    };
  }; 

  # Instala Virt-Manager y configura sus permisos
  programs.virt-manager.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  networking.firewall = {
    enable = true;
    # Abrir puertos para LocalSend
    allowedTCPPorts = [ 53317 ];
    allowedUDPPorts = [ 53317 ];
  };

  # Esto NO se cambia supongo
  system.stateVersion = "25.11";

}