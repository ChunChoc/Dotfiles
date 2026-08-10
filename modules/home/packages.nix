{
  pkgs,
  lib,
  osConfig,
  ...
}:

{
  # Paquetes de usuario. Los grupos opcionales se activan con los flags
  # myFeatures del host (leídos desde la config NixOS vía osConfig).
  home.packages =
    with pkgs;
    [
      # GUI Utils
      # La terminal es Ghostty y la instala programs/ghostty.nix (necesita el
      # módulo para la unit de systemd y la activación por D-Bus)
      # El gestor de archivos es Yazi y lo instala programs/yazi.nix (necesita el
      # módulo para el tema, las dependencias de vista previa y el handler de
      # inode/directory). Sustituyó a Nautilus; ver el comentario de ese módulo.
      #brave
      brave-origin
      mullvad-browser
      mpv
      imv
      zathura
      file-roller
      obsidian
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
      herdr
      pokeget-rs

      # System Utils
      xwayland-satellite
      # `wl-copy` / `wl-paste`: el portapapeles de Wayland desde la terminal.
      # Va aquí y no en las extraPackages de Yazi porque no es cosa suya: Yazi
      # lo usa (sin él, la tecla `C` copia la ruta dentro de Yazi pero no la
      # deja en el portapapeles del sistema), pero también sirve en scripts y
      # a mano, p. ej. `wl-copy -t image/png < foto.png` para meter una imagen
      # de verdad, no su ruta.
      wl-clipboard
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
      libreoffice-fresh # editor diario; toma las fuentes del sistema vía fontconfig
      hunspellDicts.es_GT # corrección ortográfica para Español (Guatemala)
      #onlyoffice-desktopeditors # para verificar fidelidad de formato .docx/.xlsx
    ];
}
