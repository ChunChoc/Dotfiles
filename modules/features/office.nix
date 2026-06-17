{ config, lib, pkgs, ... }:

let
  # OnlyOffice corre en un sandbox FHS (bubblewrap) y descubre fuentes escaneando
  # únicamente /usr/share/fonts dentro del sandbox. buildFHSEnv puebla esa ruta
  # fusionando el share/fonts de cada paquete listado en targetPkgs (así llega
  # noto-fonts-cjk-sans en el paquete original). Por eso las fuentes se añaden aquí
  # y no parcheando share/desktopeditors/fonts, que OnlyOffice no escanea.
  onlyofficeWithFonts = pkgs.onlyoffice-desktopeditors.override {
    buildFHSEnv = args:
      pkgs.buildFHSEnv (args // {
        targetPkgs = pkgs':
          (args.targetPkgs pkgs') ++ (with pkgs; [
            corefonts            # Arial, Times New Roman, Courier New, Verdana, Georgia, ...
            vista-fonts          # Calibri, Cambria, Candara, Consolas, Constantia, Corbel
            liberation_ttf       # Liberation Sans/Serif/Mono (métricas de Arial/Times/Courier)
            liberation-sans-narrow
          ]);
      });
  };
in
{
  config = lib.mkIf config.myFeatures.office {
    home-manager.users.chunchoc = { lib, ... }: {
      home.packages = [
        onlyofficeWithFonts
      ];

      home.activation.refreshOnlyOfficeFonts = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        fonts_dir="/home/chunchoc/.local/share/onlyoffice/desktopeditors/data/fonts"
        all_fonts="$fonts_dir/AllFonts.js"

        if [ -e "$all_fonts" ] && ! ${pkgs.gnugrep}/bin/grep -q '"Arial"' "$all_fonts"; then
          ${pkgs.coreutils}/bin/rm -rf "$fonts_dir"
        fi
      '';
    };
  };
}
