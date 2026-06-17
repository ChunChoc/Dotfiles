{ config, lib, pkgs, ... }:

let
  onlyofficeWithFonts = pkgs.onlyoffice-desktopeditors.override {
    buildFHSEnv = args:
      pkgs.buildFHSEnv (args // {
        targetPkgs = pkgs':
          map (pkg:
            if (pkg.pname or null) == "onlyoffice-desktopeditors" then
              pkg.overrideAttrs (old: {
                postInstall = (old.postInstall or "") + ''
                  mkdir -p $out/share/desktopeditors/fonts/extra

                  for font in \
                    ${pkgs.corefonts}/share/fonts/truetype/* \
                    ${pkgs.vista-fonts}/share/fonts/truetype/* \
                    ${pkgs.liberation_ttf}/share/fonts/truetype/* \
                    ${pkgs.liberation-sans-narrow}/share/fonts/truetype/*; do
                    case "$font" in
                      *.ttf|*.ttc) ln -sf "$font" "$out/share/desktopeditors/fonts/extra/$(basename "$font")" ;;
                    esac
                  done
                '';
              })
            else
              pkg
          ) (args.targetPkgs pkgs');
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
