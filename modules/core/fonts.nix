{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      corefonts
      vista-fonts
      liberation_ttf
      liberation-sans-narrow
      nerd-fonts.jetbrains-mono
    ];

    fontconfig.enable = true;
  };
}
