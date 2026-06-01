{ pkgs, ... }:

{
  # Paquetes de usuario
  home.packages = with pkgs; [
    # GUI Utils
    alacritty nautilus brave
    mpv imv file-roller localsend

    # CLI Utils
    git wget curl tree htop
    eza bat fzf fd
    pokeget-rs

    # System Utils
    xwayland-satellite

    # Fuente
    nerd-fonts.jetbrains-mono
  ];

  # Habilitar fuentes
  fonts.fontconfig.enable = true;
}
