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
    # La fuente de la INTERFAZ de las apps GTK: menús, botones, etiquetas y
    # sobre todo los diálogos de abrir/guardar. Es la misma que usa DMS
    # (settings.json, "fontFamily"), así que el diálogo de guardar de Brave y la
    # barra del escritorio se leen con la misma letra.
    #
    # Antes era JetBrainsMono Nerd Font: una monoespaciada de programar haciendo
    # de fuente de interfaz. Se queda solo donde hay código, que es la terminal
    # (programs/ghostty.nix, con su propia configuración de fuente y ajena a
    # esto) y el `monospace-font-name` de aquí abajo.
    #
    # Roboto Flex está instalada a nivel de sistema en core/fonts.nix, que es
    # donde tiene que estar para que la vean tanto Qt (DMS) como fontconfig.
    #
    # Esta opción no escribe en un solo sitio: home-manager la vuelca en el
    # settings.ini de GTK3 y GTK4 y, además, en el font-name de dconf
    # (modules/misc/gtk/gtk3.nix:162). Hacen falta los dos, porque el diálogo de
    # Brave no lo dibuja Brave sino xdg-desktop-portal-gnome, que es un proceso
    # aparte y de los que leen la configuración por gsettings.
    font = {
      name = "Roboto Flex";
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

      # El `font-name` NO se pone aquí: lo escribe home-manager a partir de
      # `gtk.font` de arriba, y declararlo en los dos sitios daría un conflicto
      # de claves duplicadas en dconf.
      #
      # El monoespaciado sí, porque `gtk.font` no lo cubre y sin esto queda al
      # valor de fábrica de GNOME (Source Code Pro), que ni siquiera está
      # instalada: cualquier app GTK que pida "monospace" acabaría en la
      # sustituta que le tocara. Aquí no hay interfaz que valga, es texto de
      # código, así que se queda JetBrains Mono igual que la terminal.
      monospace-font-name = "JetBrainsMono Nerd Font 11";
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
