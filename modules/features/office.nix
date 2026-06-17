{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.myFeatures.office {
    home-manager.users.chunchoc = {
      home.packages = with pkgs; [
        libreoffice-fresh        # editor diario; toma las fuentes del sistema vía fontconfig
        onlyoffice-desktopeditors # para verificar fidelidad de formato .docx/.xlsx
      ];
    };
  };
}
