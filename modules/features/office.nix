{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.myFeatures.office {
    home-manager.users.chunchoc.home.packages = with pkgs; [
      onlyoffice-desktopeditors
    ];
  };
}
