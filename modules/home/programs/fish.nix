{ ... }:

{
  xdg.configFile."fish/themes/dms.theme".source = ../dotfiles/fish/themes/dms.theme;

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
      grep = "rg";
      root = "run0 --background=";
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

      # Sin `cd`: se trabaja sobre ~/Dotfiles con `--flake` y `git -C`, así el
      # shell termina en el mismo directorio desde donde llamaste el comando.
      # Incluye llm-agents (OpenCode); no aplicar si falló la actualización.
      upgrade = ''
        nix flake update --flake ~/Dotfiles; or return
        git -C ~/Dotfiles add flake.lock; or return
        run0 --background= nixos-rebuild switch --flake ~/Dotfiles#(hostname)
      '';
    };

    interactiveShellInit = ''
       set -g fish_greeting
       fish_config theme choose dms

      # OJO: secrets.env NO se carga aquí a propósito. Exportar las API keys
      # en cada shell las regala a todo proceso hijo (cualquier paquete npm
      # malicioso podría leerlas). Los wrappers MCP (claude.nix) cargan el
      # archivo por sí mismos justo antes de usarlas.

      fastfetch
    '';
  };
}
