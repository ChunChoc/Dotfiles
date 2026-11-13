{
  lib,
  runCommand,
  hyperframes,
  src,
  skills,
}:

# Skills de HyperFrames tomadas del input `hyperframes` del flake (fijado por
# flake.lock), adaptadas a la CLI de Nix: los ejemplos `npx hyperframes ...` pasan a
# `hyperframes ...` para que el agente use la versión del PATH y no baje otra de npm.
let
  upstreamVersion = (lib.importJSON "${src}/plugin.json").version;

  nixNote = ''

    > **Instalación Nix (Dotfiles):** la CLI `hyperframes` ${hyperframes.version} ya está en el PATH,
    > con Chrome headless, FFmpeg, whisper-cpp y Kokoro (TTS) resueltos por Nix. Llámala directo
    > (`hyperframes <comando>`), nunca con `npx`/`bunx`/`hyperframes@latest`. No ejecutes
    > `hyperframes skills update`, `hyperframes upgrade` ni `npx skills add`: versión y skills se
    > actualizan cambiando el flake de ~/Dotfiles. Si un comando pide instalar un navegador o un
    > runtime, es un fallo de entorno: repórtalo en vez de descargar nada.
  '';
in
assert lib.assertMsg (upstreamVersion == hyperframes.version)
  "hyperframes: las skills (input del flake, ${upstreamVersion}) y la CLI (pkgs/hyperframes, ${hyperframes.version}) deben ser la misma release";
runCommand "hyperframes-skills-${hyperframes.version}" { } ''
  mkdir -p $out
  ${lib.concatMapStringsSep "\n" (s: "cp -r ${src}/skills/${s} $out/${s}") skills}
  chmod -R u+w $out

  # Solo documentación: los .mjs ya resuelven la CLI con HYPERFRAMES_CLI_ENTRY.
  find $out -type f -name '*.md' -print0 \
    | xargs -0 sed -i -E \
        -e 's/npx (-y |--yes )?hyperframes@(latest|<that version>)/hyperframes/g' \
        -e 's/(npx|bunx) (-y |--yes )?hyperframes\b/hyperframes/g'

  # Nota tras el frontmatter del SKILL.md principal (las demás skills lo leen primero).
  awk -v note=${lib.escapeShellArg nixNote} '
    { print }
    /^---$/ && ++n == 2 { print note }
  ' $out/hyperframes/SKILL.md > SKILL.md
  mv SKILL.md $out/hyperframes/SKILL.md
''
