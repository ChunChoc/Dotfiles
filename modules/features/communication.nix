{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.myFeatures.communication {
    home-manager.users.chunchoc.home.packages = with pkgs; [
      discord
      signal-desktop
    ];
  };
}
