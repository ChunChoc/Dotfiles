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
      # Nautilus se declara aquí aunque el módulo de niri ya lo mete en el
      # closure por su cuenta (programs.niri.useNautilus, activo por defecto:
      # se lo pasa a services.dbus.packages para el FileChooser del portal de
      # GNOME). Eso solo lo hace activable por D-Bus —de ahí sale el "mostrar
      # en carpeta" de los navegadores—, pero no instala el .desktop ni lo pone
      # en el PATH, así que sin esta línea no habría forma de abrirlo a mano.
      nautilus
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
