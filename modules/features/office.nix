{ config, lib, pkgs, ... }:

let
  onlyofficeFontsDir = pkgs.runCommand "onlyoffice-fonts" { } ''
    mkdir -p $out

    for font in \
      ${pkgs.corefonts}/share/fonts/truetype/* \
      ${pkgs.vista-fonts}/share/fonts/truetype/* \
      ${pkgs.liberation_ttf}/share/fonts/truetype/* \
      ${pkgs.liberation-sans-narrow}/share/fonts/truetype/*; do
      ln -s "$font" "$out/$(basename "$font")"
    done
  '';
in
{
  config = lib.mkIf config.myFeatures.office {
    home-manager.users.chunchoc = { lib, ... }: {
      home.packages = [
        pkgs.onlyoffice-desktopeditors
      ];

      xdg.dataFile."fonts/onlyoffice" = {
        source = onlyofficeFontsDir;
        recursive = true;
      };

      home.activation.refreshOnlyOfficeFonts = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        ${pkgs.fontconfig}/bin/fc-cache -f /home/chunchoc/.local/share/fonts

        fonts_dir="/home/chunchoc/.local/share/onlyoffice/desktopeditors/data/fonts"
        all_fonts="$fonts_dir/AllFonts.js"

        if [ -e "$all_fonts" ] && ! ${pkgs.gnugrep}/bin/grep -q '"Arial"' "$all_fonts"; then
          ${pkgs.coreutils}/bin/rm -rf "$fonts_dir"
        fi
      '';
    };
  };
}
