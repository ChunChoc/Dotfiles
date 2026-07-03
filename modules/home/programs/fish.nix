{ pkgs, ... }:

let
  niriSessionTTY = pkgs.writeShellScript "niri-session-tty" ''
    if systemctl --user -q is-active niri.service; then
      echo 'A niri session is already running.'
      exit 1
    fi

    systemctl --user reset-failed

    env_vars=""
    while IFS='=' read -r name _; do
      case "$name" in
        "" | [0-9]* | *[!A-Za-z0-9_]* ) continue ;;
      esac
      env_vars="$env_vars $name"
    done <<EOF
$(env)
EOF

    if [ -n "$env_vars" ]; then
      systemctl --user import-environment $env_vars
    fi

    if [ -n "$env_vars" ] && command -v dbus-update-activation-environment >/dev/null 2>&1; then
      dbus-update-activation-environment $env_vars
    fi

    systemctl --user --wait start niri.service
    systemctl --user start --job-mode=replace-irreversibly niri-shutdown.target
    systemctl --user unset-environment WAYLAND_DISPLAY DISPLAY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP NIRI_SOCKET
  '';
in

{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fish = {
    enable = true;

    shellAbbrs = {
      ls = "eza --icons --group-directories-first";
      ll = "eza -l --icons --group-directories-first";
      cat = "bat";
      sudo = "run0 --background=";
      root = "run0 --background=";
    };

    functions = {
      ff = ''
        fd --hidden --exclude .git | fzf
      '';

      vf = ''
        set file (ff)
        test -n "$file"; and vim "$file"
      '';

      bf = ''
        set file (ff)
        test -n "$file"; and bat "$file"
      '';

      cf = ''
        set file (ff)
        test -n "$file"; and cd (dirname "$file")
      '';

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
      fish_config theme choose catppuccin-mocha --color-theme=dark

      if test -f ~/Dotfiles/.secrets/secrets.env
        source ~/Dotfiles/.secrets/secrets.env
      end

      if test (tty) = /dev/tty1; and not set -q WAYLAND_DISPLAY; and not set -q DISPLAY; and not set -q NIRI_SOCKET
        exec ${niriSessionTTY}
      end

      pokeget random --hide-name
    '';
  };
}
