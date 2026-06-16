{ pkgs, ... }:

{
  # Paquetes de usuario
  home.packages = with pkgs; [
    # GUI Utils
    alacritty nautilus brave mullvad-browser
    mpv imv zathura file-roller localsend
    obsidian tauon

    # CLI Utils
    git wget curl tree htop
    eza bat fzf fd
    pokeget-rs

    # System Utils
    xwayland-satellite
  ];
}
