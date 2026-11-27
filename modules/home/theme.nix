{
  pkgs,
  lib,
  config,
  ...
}:

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
  # gtk-im-context-simple compone en el propio cliente. El problema se detectó
  # en un cliente GTK, pero afecta a cualquier app GTK bajo este compositor.
  # Se conserva para esas aplicaciones; Alacritty no depende de GTK.
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
  }
  // gtkImModule;

  # Las de arriba solo llegan a lo que arranca desde el shell o desde niri:
  # home.sessionVariables escribe hm-session-vars.sh, que systemd no lee. Los
  # units de usuario se alimentan de ~/.config/environment.d, y ahí solo
  # escribe systemd.user.sessionVariables. Por eso el módulo de entrada va
  # declarado en los dos sitios para que las aplicaciones GTK iniciadas como
  # servicios de usuario también compongan las teclas muertas correctamente.
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
      # Conservar los iconos existentes. Su sustitución por los iconos nativos
      # de DMS queda pendiente; ya no se actualiza el acento por wallpaper.
      name = "Papirus-Dark-Accent";
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
    # (programs/alacritty.nix, con su propia configuración de fuente y ajena a
    # esto) y el `monospace-font-name` de aquí abajo.
    #
    # Roboto Flex está instalada a nivel de sistema en core/fonts.nix, que es
    # donde tiene que estar para que la vean tanto Qt (DMS) como fontconfig.
    #
    # Esta opción no escribe en un solo sitio: home-manager la vuelca en el
    # settings.ini de GTK3 y GTK4 y, además, en el font-name de dconf
    # (modules/misc/gtk/gtk3.nix:162). Hacen falta los dos para las apps GTK y
    # los procesos de GNOME que leen la configuración por gsettings. El
    # selector de archivos ahora es Dux Files y sigue la tipografía de DMS.
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
      icon-theme = "Papirus-Dark-Accent";

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
  # Catppuccin. Esto aplica a todo GTK4, no solo al gestor de archivos.
  xdg.configFile = {
    "gtk-4.0/assets".source =
      "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
    "gtk-4.0/gtk.css".source =
      "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
    "gtk-4.0/gtk-dark.css".source =
      "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
  };

  # Conservar el overlay actual de Papirus, sin cambiar los enlaces de tamaño
  # ni el último acento elegido. La gestión de iconos con DMS queda pendiente.
  xdg.dataFile."icons/Papirus-Dark-Accent/index.theme".text =
    let
      sizes = [
        22
        24
        32
        48
        64
      ];
      dir = s: "${toString s}x${toString s}/places";
    in
    ''
      [Icon Theme]
      Name=Papirus-Dark-Accent
      Comment=Papirus-Dark con las carpetas del acento del wallpaper
      Inherits=Papirus-Dark,breeze-dark,hicolor
      Directories=${lib.concatMapStringsSep "," dir sizes}
    ''
    + lib.concatMapStrings (s: ''

      [${dir s}]
      Context=Places
      Size=${toString s}
      Type=Fixed
    '') sizes;

  # Mantener disponibles los destinos del overlay existente hasta sustituir
  # Papirus. Esto no ejecuta ningún generador ni cambia colores al iniciar.
  xdg.dataFile."icons/Papirus-Dark-Accent/accents".source =
    pkgs.runCommand "papirus-folder-accents" { }
      ''
        src=${config.gtk.iconTheme.package}/share/icons/Papirus
        for accent in rosewater flamingo pink mauve red maroon peach yellow green teal sky sapphire blue lavender; do
          for size in 22 24 32 48 64; do
            dir="$src/''${size}x''${size}/places"
            out_dir="$out/$accent/''${size}x''${size}/places"
            mkdir -p "$out_dir"
            find "$dir/" -maxdepth 1 -type l -lname '*cat-mocha-mauve*' -printf '%f\t%l\n' |
              while IFS=$'\t' read -r name target; do
                ln -s "$dir/''${target//cat-mocha-mauve/cat-mocha-$accent}" "$out_dir/$name"
              done
          done
        done
      '';
}
