{ ... }:

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
      cd = "z";
      ls = "eza --icons --group-directories-first";
      ll = "eza -l --icons --group-directories-first";
      cat = "bat";
      root = "run0 --background=";
      nd = "nix develop --command fish";
    };

    functions = {
      sudo = ''
        run0 --background= $argv
      '';

      sudoreal = ''
        command sudo $argv
      '';

      ff = ''
        fd --hidden --exclude .git | fzf
      '';

       vf = ''
         set file (ff)
        test -n "$file"; and nvim "$file"
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
       fish_config theme choose catppuccin-mocha --color-theme=dark

      if test -f ~/Dotfiles/.secrets/secrets.env
        source ~/Dotfiles/.secrets/secrets.env
      end

      # Dentro de un devShell de Nix: usar un starship distinto (catppuccin mocha
      # minimal) para diferenciar visualmente el entorno de proyecto. Fuera de un
      # devShell, STARSHIP_CONFIG queda sin definir y se usa ~/.config/starship.toml.
      if set -q IN_NIX_SHELL
        set -gx STARSHIP_CONFIG "$HOME/.config/starship-dev.toml"
      end

      # El pokémon solo en terminales normales; dentro de un devShell de Nix
      # (donde ya cambia el prompt a starship-dev.toml) no lo mostramos.
      if not set -q IN_NIX_SHELL
        pokeget random --hide-name
      end
    '';
  };
}
