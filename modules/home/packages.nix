{ pkgs, lib, osConfig, ... }:

{
  # Paquetes de usuario. Los grupos opcionales se activan con los flags
  # myFeatures del host (leídos desde la config NixOS vía osConfig).
  home.packages = with pkgs; [
    # GUI Utils
    alacritty
    nautilus
    brave
    mullvad-browser
    mpv
    imv
    zathura
    file-roller
    obsidian
    tauon

    # CLI Utils
    git
    wget
    curl
    tree
    htop
    eza
    bat
    fzf
    fd
    herdr
    pokeget-rs

    # System Utils
    xwayland-satellite
  ]
  ++ lib.optionals osConfig.myFeatures.communication [
    #vesktop alternativa de discord que sí funciona en teoría.
    discord # temporal: para depurar screen share; ver plan
    signal-desktop
  ]
  ++ lib.optionals osConfig.myFeatures.office [
    libreoffice-fresh        # editor diario; toma las fuentes del sistema vía fontconfig
    #onlyoffice-desktopeditors # para verificar fidelidad de formato .docx/.xlsx
  ];
}
