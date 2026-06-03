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

      if test -f ~/Dotfiles/.secrets/secrets.env
        source ~/Dotfiles/.secrets/secrets.env
      end

      if test (tty) = /dev/tty1; and not set -q WAYLAND_DISPLAY; and not set -q DISPLAY; and not set -q NIRI_SOCKET
        exec niri-session
      end

      pokeget random --hide-name
    '';
  };
}
