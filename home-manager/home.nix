{ config, pkgs, ... }: # Ya no es estrictamente necesario 'inputs' aquí para DMS

{
  # BORRA la línea de imports = [ inputs.dms... ]; YA NO SE USA.

  home.username = "chunchoc";       # <--- REVISA ESTO
  home.homeDirectory = "/home/chunchoc"; # <--- REVISA ESTO

  # Tus Dotfiles (Esto se mantiene igual, está perfecto)
  xdg.configFile."niri/config.kdl".source = ./dotfiles/niri/config.kdl;
  xdg.configFile."alacritty/alacritty.toml".source = ./dotfiles/alacritty/alacritty.toml;
  xdg.configFile."starship.toml".source = ./dotfiles/starship/starship.toml;
  xdg.configFile."DankMaterialShell/settings.json".source = ./dotfiles/DankMaterialShell/settings.json;

  # Gestionar dictorios automáticos (Downloads, Pictures, ...)
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };


  # Paquetes locales
  home.packages = with pkgs; [
    alacritty     # Emulador de terminal
    fuzzel        # Lanzador de aplicaciones por defecto
    xwayland-satellite          
    vscodium      # vscode open source
    zed-editor	  # Editor de texto
    brave 	  # Navegador
    nautilus      # El gestor de archivos (GNOME Files)
    file-roller   # Para extraer zips/rars desde Nautilus
    htop   	  # Ver procesos
    tree	  # Mostrar el contenido de un directorio
    localsend     # Enviar archivos locales
    pokeget-rs    # Pokemones en terminal
    nerd-fonts.jetbrains-mono    # Fuente Jetbrains Nerd	 
  ];

  # Habilitar fuentes
  fonts.fontconfig.enable = true;

  #------------------ZSH-------------------------------------------
  # 1. Habilitar starship
  programs.starship.enable = true;

  # 2. Configuración de Zsh (Reemplaza tu .zshrc)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    
    # Plugins nativos (sin necesitar Oh My Zsh)
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Historial
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;     # No guardar duplicados
      share = true;          # Compartir historia entre terminales
    };

    # Variables de entorno o alias
    shellAliases = {
      ll = "ls -l";
      update = "sudo nixos-rebuild switch --flake ~/Dotfiles#nixos-vm";
    };
    
    # Si tenías comandos sueltos en tu .zshrc, van aquí:
    initContent = ''
      # Cualquier cosa extra que solías poner en .zshrc
      export EDITOR=vim
      pokeget random --hide-name
    '';
  };
 #----------------------------------------------------------------
  home.sessionVariables = {
    # Fuerza a las apps GTK/Flutter (como LocalSend) a usar Wayland
    GDK_BACKEND = "wayland";
    
    # Opcional pero recomendado: Fuerza apps QT a usar Wayland también
    QT_QPA_PLATFORM = "wayland";
    
    # Quitarle la barra a LocalSend a la fuerza
    GTK_CSD = "0";
  };
 #-----------------------------------------------------------------
  # ... en home.nix ...

  # 1. ESTO ARREGLA BRAVE Y LE DICE AL SISTEMA QUE ES "DARK MODE"
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # 2. Configuración GTK mejorada
  gtk = {
    enable = true;

    theme = {
      name = "catppuccin-mocha-mauve-standard+default";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
        size = "standard";
        tweaks = [ "rimless" ];
        variant = "mocha";
      };
    };

    # ÍCONOS: Usamos la versión de Catppuccin para tener carpetas VIOLETAS (Mauve)
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

    # Esto fuerza a Brave y apps rebeldes a usar modo oscuro
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # 3. Mantenemos el truco de Nautilus (GTK4) que ya tenías
  xdg.configFile = {
    "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
    "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
    "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
  };
  #-----------------------------------------------------------------------------------------------------------------------------

  programs.home-manager.enable = true;
  home.stateVersion = "25.11"; # O 25.05/25.11 según te diga el warning, no importa mucho en unstable
}
