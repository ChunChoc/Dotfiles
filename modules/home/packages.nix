{ pkgs, ... }:

{
  # Paquetes de usuario
  home.packages = with pkgs; [
    # GUI Utils
    alacritty fuzzel nautilus vscodium brave
    mpv imv file-roller localsend

    # CLI Utils
    git wget curl tree htop
    pokeget-rs python3

    # System Utils
    xwayland-satellite

    # Fuente
    nerd-fonts.jetbrains-mono
  ];

  # Habilitar fuentes
  fonts.fontconfig.enable = true;
}
