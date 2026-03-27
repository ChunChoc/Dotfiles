{ config, ... }:

{
  # ZSH & Starship
  programs.starship.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Historial
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      share = true;
    };

    # Alias
    shellAliases = {
      ll = "ls -l";
      sudo = "run0 --background=";
      root = "run0 --background=";
    };

    # Comandos de inicio
    initContent = ''
      export EDITOR=vim
      pokeget random --hide-name

      # Aliases dinámicos que usan el hostname actual
      alias update='run0 --background= nixos-rebuild switch --flake ~/Dotfiles#$(hostname)'
      alias upgrade='cd ~/Dotfiles && nix flake update && git add flake.lock && run0 --background= nixos-rebuild switch --flake .#$(hostname)'
    '';
  };
}
