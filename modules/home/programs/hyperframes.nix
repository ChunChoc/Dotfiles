{
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:

# HyperFrames (https://github.com/heygen-com/hyperframes): videos escritos en HTML.
# CLI y skills salen de la misma release, fijada en flake.lock + pkgs/hyperframes.
# En un proyecto basta `hyperframes init <nombre>`; `bun run render` usa esta CLI.
let
  hyperframes = pkgs.callPackage ../../../pkgs/hyperframes { };

  # Set "core" que recomienda upstream. Otras (slideshow, figma,
  # remotion-to-hyperframes) se activan agregándolas aquí.
  skillNames = [
    "hyperframes"
    "hyperframes-cli"
    "hyperframes-registry"
    "media-use"
    "reverse-any-video"
    "style-sampling"
  ];

  skills = pkgs.callPackage ../../../pkgs/hyperframes/skills.nix {
    inherit hyperframes;
    src = inputs.hyperframes;
    skills = skillNames;
  };
in
{
  config = lib.mkIf osConfig.myFeatures.hyperframes {
    home.packages = [
      hyperframes
      # Las skills también llaman a ffmpeg/ffprobe directamente.
      pkgs.ffmpeg
    ];

    # Para los scripts de las skills, que lanzan la CLI con `node` sin el wrapper.
    home.sessionVariables = hyperframes.env;

    # ~/.claude/skills también lo lee OpenCode.
    home.file = lib.genAttrs (map (s: ".claude/skills/${s}") skillNames) (name: {
      source = "${skills}/${lib.removePrefix ".claude/skills/" name}";
      recursive = true;
      force = true;
    });
  };
}
