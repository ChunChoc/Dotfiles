{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.myFeatures.gaming {
    # Soporte para Steam
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    # Soporte 32-bit necesario para muchos juegos
    hardware.graphics.enable32Bit = true;

    # Paquetes adicionales para gaming
    environment.systemPackages = with pkgs; [
      # wine
      # winetricks
      # lutris
      # heroic
    ];
  };
}
