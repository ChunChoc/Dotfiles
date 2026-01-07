{ config, pkgs, ... }: # Ya no es estrictamente necesario 'inputs' aquí para DMS

{
  # BORRA la línea de imports = [ inputs.dms... ]; YA NO SE USA.

  home.username = "chunchoc";       # <--- REVISA ESTO
  home.homeDirectory = "/home/chunchoc"; # <--- REVISA ESTO

  # Tus Dotfiles (Esto se mantiene igual, está perfecto)
  xdg.configFile."niri/config.kdl".source = ./dotfiles/niri/config.kdl;
  xdg.configFile."alacritty/alacritty.toml".source = ./dotfiles/alacritty/alacritty.toml;
  xdg.configFile."starship.toml".source = ./dotfiles/starship/starship.toml;

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
  };

  programs.home-manager.enable = true;
  home.stateVersion = "25.11"; # O 25.05/25.11 según te diga el warning, no importa mucho en unstable
}
