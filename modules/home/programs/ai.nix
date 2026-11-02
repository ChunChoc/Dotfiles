{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:

{
  # Config de agentes AI (OpenCode + skills compartidas en la ruta compatible de Claude).
  # Los binarios (opencode, claude-code) los instala el feature development.
  config = lib.mkIf osConfig.myFeatures.development {
    xdg.configFile."opencode/opencode.json".source = ../dotfiles/ai/opencode/opencode.json;

    # Servidor y navegador fijados por flake.lock; sin descargas de npm ni de Chromium.
    # El contexto aislado no reutiliza el perfil personal de Brave.
    home.file.".local/bin/playwright-mcp" = {
      executable = true;
      text = ''
        #!${pkgs.runtimeShell}
        exec ${lib.getExe pkgs.playwright-mcp} \
          --executable-path=${lib.getExe pkgs.brave-origin} \
          --isolated \
          "$@"
      '';
    };

    home.file = {
      # Instrucciones globales para agentes: un solo archivo, enlazado FUERA de la store
      # (como la config de nvim) para poder editarlo y que aplique sin rebuild.
      # Lo que es regla de un repo va en el AGENTS.md de ese repo.
      ".claude/CLAUDE.md".source =
        config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/Dotfiles/modules/home/dotfiles/ai/AGENTS.md";

      ".config/opencode/AGENTS.md".source =
        config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/Dotfiles/modules/home/dotfiles/ai/AGENTS.md";

      ".claude/skills/frontend-design" = {
        source = inputs.anthropic-skills.outPath + "/skills/frontend-design";
        recursive = true;
        force = true;
      };
    };
  };
}
