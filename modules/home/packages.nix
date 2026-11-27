{
  pkgs,
  lib,
  osConfig,
  inputs,
  ...
}:

{
  # Paquetes de usuario. Los grupos opcionales se activan con los flags
  # myFeatures del host (leídos desde la config NixOS vía osConfig).
  home.packages =
    with pkgs;
    [
      # GUI Utils
      # La terminal es Alacritty y la instala programs/alacritty.nix.
      # Dux Files lo instala programs.dux-files en modules/desktop.nix, con
      # D-Bus y polkit. El tema GTK se conserva para las demás aplicaciones.
      # Dux sigue colores y tipografía de DMS en vivo con sus defaults "auto".
      #brave
      brave-origin
      mpv
      imv
      zathura
      #appflowy
      # La música la manejan MPD + rmpc (programs/mpd.nix), antes tauon

      # CLI Utils
      git
      wget
      curl
      tree
      htop
      eza
      fd
      # Fijado a otro nixpkgs: ver `nixpkgs-herdr` en flake.nix.
      inputs.nixpkgs-herdr.legacyPackages.${pkgs.stdenv.hostPlatform.system}.herdr
      pokeget-rs

      # System Utils
      xwayland-satellite
    ]
    ++ lib.optionals osConfig.myFeatures.development [
      gh
    ]
    ++ lib.optionals osConfig.myFeatures.communication [
      #vesktop alternativa de discord que sí funciona en teoría.
      #discord # temporal: para depurar screen share; ver plan
      signal-desktop
    ]
    ++ lib.optionals osConfig.myFeatures.office [
      libreoffice-stable # editor diario; toma las fuentes del sistema vía fontconfig
      hunspellDicts.es_GT # corrección ortográfica para Español (Guatemala)
      #onlyoffice-desktopeditors # para verificar fidelidad de formato .docx/.xlsx
    ]
    ++ lib.optionals osConfig.myFeatures.gaming.minecraft [
      # Minecraft Java. Prism trae sus propios JDK y arregla las rutas de
      # glfw/openal; el launcher oficial es un binario dinámico de fuera de Nix
      # y no arranca sin envoltorio FHS. Login con cuenta Microsoft incluido.
      prismlauncher
    ];
}
