{ pkgs, config, ... }:

{
  # Variables de entorno visuales
  home.sessionVariables = {
    GDK_BACKEND = "wayland";
    QT_QPA_PLATFORM = "wayland";
    GTK_CSD = "0";
  };

  # Configuración del puntero (Cursor)
  home.pointerCursor = {
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
      package = pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
        size = "standard";
        tweaks = [ "rimless" ];
        variant = "mocha";
      };
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

  # Hacks de CSS para Nautilus
  xdg.configFile = {
    "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
    "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
    "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
  };

  xdg.dataFile."applications/LocalSend.desktop".text = ''
    [Desktop Entry]
    Categories=GTK;FileTransfer;Utility
    Exec=env GTK_CSD=0 localsend_app %U
    GenericName=An open source cross-platform alternative to AirDrop
    Icon=localsend
    Keywords=Sharing;LAN;Files
    Name=LocalSend
    StartupNotify=true
    StartupWMClass=localsend_app
    Terminal=false
    Type=Application
    Version=1.5
  '';
}
