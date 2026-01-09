{ pkgs, ... }:
{
  # Usar systemd-boot como menú de arranque
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 3;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Usar la última verión del kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;
}