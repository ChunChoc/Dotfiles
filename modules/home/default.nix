{ ... }:

{
  imports = [
    ./theme.nix
    ./packages.nix
    ./localsend.nix
    ./network-lab.nix
    ./prism.nix
    ./virtualization.nix
    ./programs/fish.nix
    ./programs/fzf.nix
    ./programs/bat.nix
    ./programs/dms.nix
    ./programs/niri-session.nix
    ./programs/ai.nix
    ./programs/hyperframes.nix
    ./programs/claude.nix
    ./programs/zed.nix
    ./programs/neovim.nix
    ./programs/lazygit.nix
    ./programs/alacritty.nix
    ./programs/herdr.nix
    ./programs/mpd.nix
    ./programs/cava.nix
    ./mime.nix
    ./wallpaper.nix
    ./clipboard-images.nix
    ./projector.nix
    ./clipboard-privacy.nix
  ];

  home.username = "chunchoc";
  home.homeDirectory = "/home/chunchoc";

  # --------------------------------------------------------
  # GESTIÓN DE DOTFILES (Enlazado estático + Generación dinámica)
  # --------------------------------------------------------
  xdg.configFile = {
    # Archivos estáticos (source)
    "starship.toml".source = ./dotfiles/starship/starship.toml;
    "fastfetch/config.jsonc".source = ./dotfiles/fastfetch/config.jsonc;
    "dsearch/config.toml".source = ./dotfiles/dsearch/config.toml;
    "helix/config.toml".source = ./dotfiles/helix/config.toml;
    # DMS y sus fragmentos de Niri son mutables; programs/dms.nix solo los
    # inicializa si faltan. La GUI conserva sus cambios entre activaciones.
    "niri/config.kdl".source = ./dotfiles/niri/config.kdl;
    # `niri/dms/colors.kdl` no se gestiona aquí: lo escribe DMS (plantilla matugen
    # `niri-colors.kdl`) cada vez que aplica el tema, con el acento vigente. Ver
    # la nota en niri/config.kdl.

  };

  # --------------------------------------------------------
  # Directorios XDG
  # --------------------------------------------------------
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
  };

  # --------------------------------------------------------
  # NO TOCAR!
  # --------------------------------------------------------
  programs.home-manager.enable = true;
  home.stateVersion = "25.11";
}
