{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.myFeatures.communication {
    home-manager.users.chunchoc.home.packages = with pkgs; [
      #vesktop alternativa de discord que sí funciona en teoría.
      discord # temporal: para depurar screen share; ver plan
      signal-desktop
    ];
  };
}
