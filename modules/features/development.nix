{
  config,
  lib,
  pkgs,
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
  config = lib.mkIf config.myFeatures.development {
    # Let editor-downloaded language servers run on NixOS when they expect
    # the conventional Linux dynamic linker at /lib64/ld-linux-x86-64.so.2.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        openssl
        stdenv.cc.cc
      ];
    };

    # Paquetes de desarrollo a nivel sistema (si los hay)
    # Por ahora los paquetes de usuario se manejan en home/packages.nix

    # Ejemplo de paquetes de sistema para desarrollo:
    environment.systemPackages = with pkgs; [
      #   git
      #   gcc
      #   gnumake
      vscodium
      zed-editor
      nil
      nixd
      opencode
      claude-code
    ];

    home-manager.users.chunchoc.xdg.configFile."opencode/opencode.json".source =
      ../home/dotfiles/ai/opencode/opencode.json;

    home-manager.users.chunchoc.home.file = {
      ".agents/.skill-lock.json" = {
        source = ../home/dotfiles/ai/.skill-lock.json;
        force = true;
      };

      ".agents/skills/django-expert" = {
        source = ../home/dotfiles/ai/skills/django-expert;
        recursive = true;
        force = true;
      };

      ".agents/skills/frontend-design" = {
        source = ../home/dotfiles/ai/skills/frontend-design;
        recursive = true;
        force = true;
      };

      ".agents/skills/ui-ux-pro-max" = {
        source = "${uiUxProMaxSkill}/.claude/skills/ui-ux-pro-max";
        recursive = true;
        force = true;
      };

      ".claude/skills/django-expert" = {
        source = ../home/dotfiles/ai/skills/django-expert;
        recursive = true;
        force = true;
      };

      ".claude/skills/frontend-design" = {
        source = ../home/dotfiles/ai/skills/frontend-design;
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
