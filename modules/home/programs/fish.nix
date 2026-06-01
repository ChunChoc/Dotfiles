{ ... }:

{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fish = {
    enable = true;

    shellAbbrs = {
      ls = "eza --icons --group-directories-first";
      ll = "eza -l --icons --group-directories-first";
      cat = "bat";
      ff = "fd --hidden --exclude .git | fzf";
      sudo = "run0 --background=";
      root = "run0 --background=";
    };

    functions = {
      update = ''
        run0 --background= nixos-rebuild switch --flake ~/Dotfiles#(hostname)
      '';

      upgrade = ''
        cd ~/Dotfiles
        nix flake update
        git add flake.lock
        run0 --background= nixos-rebuild switch --flake .#(hostname)
      '';
    };

    interactiveShellInit = ''
      set -g fish_greeting
      set -gx EDITOR vim
      pokeget random --hide-name
    '';
  };
}
