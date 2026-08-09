{ pkgs, config, ... }:

let
  pythonForCatppuccinGtk = pkgs.python313.override {
    packageOverrides = _: super: {
      catppuccin = super.catppuccin.overridePythonAttrs (_: {
        doCheck = false;
        pythonImportsCheck = [ ];
      });
    };
  };

  catppuccinGtk = pkgs.catppuccin-gtk.override {
    python3 = pythonForCatppuccinGtk;
    accents = [ "mauve" ];
    size = "standard";
    tweaks = [ "rimless" ];
    variant = "mocha";
  };

  # Teclas muertas (el acento del layout latam) en aplicaciones GTK.
  #
  # GTK bajo Wayland elige por defecto el contexto de entrada "wayland", que
  # espera que la composición la provea un método de entrada del compositor.
  # niri anuncia zwp_text_input_manager_v3 pero no compone nada por su cuenta,
  # solo hace de puente hacia un IME; sin ninguno corriendo la tecla muerta se
  # descarta y la vocal llega pelada (´ + a daba "a" en vez de "á").
  #
  # Comprobado tecleando con un teclado virtual y leyendo los bytes del pty:
  #   Ghostty tal cual .................. 61 61      -> "aa"
  #   foot (compone con xkbcommon) ...... 61 c3 a1   -> "aá"
  #   Ghostty con esta variable ......... 61 c3 a1   -> "aá"
  #
  # gtk-im-context-simple compone en el propio cliente. El problema se detectó
  # en Ghostty, pero se pone a nivel de escritorio porque afecta a cualquier
  # app GTK bajo este compositor.
  #
  # Efecto secundario: desactiva los IME (fcitx, ibus). No usas ninguno; si
  # algún día ocupas escritura china o japonesa, esto es lo primero que quitar.
  gtkImModule = {
    GTK_IM_MODULE = "gtk-im-context-simple";
  };
in

{
  # Variables de entorno visuales
  home.sessionVariables = {
    GDK_BACKEND = "wayland";
    QT_QPA_PLATFORM = "wayland";
    GTK_CSD = "0";
  } // gtkImModule;

  # Las de arriba solo llegan a lo que arranca desde el shell o desde niri:
  # home.sessionVariables escribe hm-session-vars.sh, que systemd no lee. Los
  # units de usuario se alimentan de ~/.config/environment.d, y ahí solo
  # escribe systemd.user.sessionVariables. Por eso el módulo de entrada va
  # declarado en los dos sitios: si faltara aquí, el daemon de Ghostty
  # (app-com.mitchellh.ghostty.service) se quedaría sin él, que es justo el
  # proceso que crea las ventanas.
  systemd.user.sessionVariables = gtkImModule;

  # Configuración del puntero (Cursor)
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  # Tema GTK (Catppuccin)
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-mauve-standard+rimless";
      package = catppuccinGtk;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "mauve";
      };
    };
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.theme = config.gtk.theme;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  # Ajustes para aplicaciones GNOME/GTK
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "catppuccin-mocha-mauve-standard+rimless";
      icon-theme = "Papirus-Dark";
    };
  };

  # libadwaita ignora `gtk-theme-name`: las apps GTK4 modernas solo respetan un
  # gtk.css propio del usuario. Sin esto, LibreOffice, los diálogos de archivo y
  # cualquier otra app GTK4 saldrían con el Adwaita de serie en vez de
  # Catppuccin. (Antes el comentario decía "hacks para Nautilus", pero no tiene
  # nada que ver con Nautilus: aplica a todo GTK4.)
  xdg.configFile = {
    "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
    "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
    "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
  };

}
