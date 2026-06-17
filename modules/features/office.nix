{ config, lib, pkgs, ... }:

let
  onlyofficeFonts = pkgs': with pkgs'; [
    corefonts
    vista-fonts
    liberation_ttf
    liberation-sans-narrow
    nerd-fonts.jetbrains-mono
  ];

  onlyofficeWithFonts = pkgs.onlyoffice-desktopeditors.override {
    buildFHSEnv = args:
      pkgs.buildFHSEnv (args // {
        targetPkgs = pkgs': (args.targetPkgs pkgs') ++ (onlyofficeFonts pkgs');
      });
  };
in
{
  config = lib.mkIf config.myFeatures.office {
    home-manager.users.chunchoc = { lib, ... }: {
      home.packages = [
        onlyofficeWithFonts
      ];

      home.activation.refreshOnlyOfficeFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        fonts_dir="/home/chunchoc/.local/share/onlyoffice/desktopeditors/data/fonts"
        all_fonts="$fonts_dir/AllFonts.js"

        if [ -e "$all_fonts" ] && ! ${pkgs.gnugrep}/bin/grep -q '"Arial"' "$all_fonts"; then
          ${pkgs.coreutils}/bin/rm -rf "$fonts_dir"
        fi
      '';
    };
  };
}
