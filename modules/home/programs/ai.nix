{
  inputs,
  lib,
  osConfig,
  ...
}:

let
  opencodeBaseConfig = builtins.fromJSON (builtins.readFile ../dotfiles/ai/opencode/opencode.json);
  opencodeConfig = opencodeBaseConfig // {
    plugin = [
      "superpowers@git+https://github.com/obra/superpowers.git#${inputs.superpowers.rev}"
    ];
  };
in

{
  # Config de agentes AI (OpenCode + skills compartidas en la ruta compatible de Claude).
  # Los binarios (opencode, claude-code) los instala el feature development.
  config = lib.mkIf osConfig.myFeatures.development {
    xdg.configFile."opencode/opencode.json".text = builtins.toJSON opencodeConfig;

    home.file = {
      ".claude/skills/django-expert" = {
        source = inputs.django-ai-plugins.outPath + "/plugins/django-expert/skills/django-expert";
        recursive = true;
        force = true;
      };

      ".claude/skills/frontend-design" = {
        source = inputs.anthropic-skills.outPath + "/skills/frontend-design";
        recursive = true;
        force = true;
      };

      ".claude/skills/ui-ux-pro-max" = {
        source = inputs.ui-ux-pro-max-skill.outPath + "/.claude/skills/ui-ux-pro-max";
        recursive = true;
        force = true;
      };
    };
  };
}
