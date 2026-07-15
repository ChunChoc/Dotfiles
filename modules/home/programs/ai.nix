{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  uiUxProMaxSkill = pkgs.fetchFromGitHub {
    owner = "nextlevelbuilder";
    repo = "ui-ux-pro-max-skill";
    rev = "v2.10.1";
    hash = "sha256-1yaqqxnoImD23kb9xHItd9F967QDIj4R+WrXL/FxWGY=";
  };
in

{
  # Config de agentes AI (OpenCode + skills compartidas de Claude/agents).
  # Los binarios (opencode, claude-code) los instala el feature development.
  config = lib.mkIf osConfig.myFeatures.development {
    xdg.configFile."opencode/opencode.json".source = ../dotfiles/ai/opencode/opencode.json;

    home.file = {
      ".agents/.skill-lock.json" = {
        source = ../dotfiles/ai/.skill-lock.json;
        force = true;
      };

      ".agents/skills/django-expert" = {
        source = ../dotfiles/ai/skills/django-expert;
        recursive = true;
        force = true;
      };

      ".agents/skills/frontend-design" = {
        source = ../dotfiles/ai/skills/frontend-design;
        recursive = true;
        force = true;
      };

      ".agents/skills/ui-ux-pro-max" = {
        source = "${uiUxProMaxSkill}/.claude/skills/ui-ux-pro-max";
        recursive = true;
        force = true;
      };

      ".claude/skills/django-expert" = {
        source = ../dotfiles/ai/skills/django-expert;
        recursive = true;
        force = true;
      };

      ".claude/skills/frontend-design" = {
        source = ../dotfiles/ai/skills/frontend-design;
        recursive = true;
        force = true;
      };

      ".claude/skills/ui-ux-pro-max" = {
        source = "${uiUxProMaxSkill}/.claude/skills/ui-ux-pro-max";
        recursive = true;
        force = true;
      };
    };
  };
}
