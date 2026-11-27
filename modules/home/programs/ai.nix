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
    # cli.json pertenece a la TUI: mantenerlo editable, sin enlazarlo a la store.
    # Migrar el tema una sola vez y conservar las demás preferencias.
    home.activation.opencodeSystemTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.writeShellScript "opencode-system-theme" ''
        set -eu
        settings="$1/opencode/cli.json"
        marker="$2/opencode/migrations/system-theme-v1"
        [ ! -e "$marker" ] && [ ! -L "$settings" ] || exit 0
        ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$settings")" "$(dirname "$marker")"
        tmp="$(${pkgs.coreutils}/bin/mktemp "$settings.XXXXXX")"
        trap '${pkgs.coreutils}/bin/rm -f "$tmp"' EXIT
        if [ -e "$settings" ]; then
          ${pkgs.jq}/bin/jq \
            '.theme = ((.theme // {}) + {"name": "system", "mode": "system"})' \
            "$settings" > "$tmp"
          ${pkgs.coreutils}/bin/chmod --reference="$settings" "$tmp"
        else
          ${pkgs.coreutils}/bin/install -m 0600 \
            "${../dotfiles/ai/opencode/cli.json}" "$tmp"
        fi
        ${pkgs.coreutils}/bin/mv -T "$tmp" "$settings"
        ${pkgs.coreutils}/bin/touch "$marker"
      ''} "${config.xdg.configHome}" "${config.xdg.stateHome}"
    '';
    # Herdr 0.9.1 instala un plugin V1 incompatible con OpenCode V2.
    xdg.configFile."opencode/plugins/herdr-agent-state.js" = {
      source = ../dotfiles/ai/opencode/herdr-agent-state.js;
      force = true;
    };

    systemd.user.paths.opencode-terminal-theme = {
      Unit.Description = "Watch DMS terminal colors for OpenCode";
      Path = {
        PathChanged = "${config.xdg.configHome}/alacritty/dank-theme.toml";
        Unit = "opencode-terminal-theme.service";
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.services.opencode-terminal-theme = {
      Unit = {
        Description = "Refresh OpenCode from the terminal palette";
        # Esperar la recarga de Alacritty y la consulta de Herdr antes de
        # pedirle a OpenCode que consulte los colores dentro de sus paneles.
        Wants = [ "herdr-terminal-theme.service" ];
        After = [ "herdr-terminal-theme.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "opencode-refresh-terminal-theme" ''
          set -eu
          signal=$(kill -l USR2)
          for pid in $(${pkgs.procps}/bin/pgrep -u "$UID" -f '(^|/)\.?opencode(-wrapped)?([[:space:]]|$)' || true); do
            case "$(${pkgs.coreutils}/bin/readlink "/proc/$pid/fd/0" || true)" in
              /dev/pts/*)
                # Solo TUIs que ya instalaron el handler nativo. Excluir el
                # servidor y las invocaciones CLI sin handler (USR2 las mataría).
                [ -r "/proc/$pid/status" ] || continue
                while read -r key mask rest; do
                  [ "$key" = "SigCgt:" ] || continue
                  if (( (16#$mask & (1 << (signal - 1))) != 0 )); then
                    kill -USR2 "$pid" 2>/dev/null || true
                  fi
                  break
                done < "/proc/$pid/status" 2>/dev/null || true
                ;;
            esac
          done
        '';
      };
    };

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
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Dotfiles/modules/home/dotfiles/ai/AGENTS.md";

      ".config/opencode/AGENTS.md".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Dotfiles/modules/home/dotfiles/ai/AGENTS.md";

      ".claude/skills/frontend-design" = {
        source = inputs.anthropic-skills.outPath + "/skills/frontend-design";
        recursive = true;
        force = true;
      };
    };
  };
}
