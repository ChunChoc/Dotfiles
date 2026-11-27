{
  lib,
  installShellFiles,
  stdenv,
  upstream,
}:

# Adaptar únicamente el empaquetado, sin parches al código de OpenCode.
# Mantener nombre/argv y completaciones para Fish, Herdr y el refresco de DMS.
assert lib.assertMsg (
  lib.versions.major upstream.version == "2"
) "Revisar la compatibilidad antes de migrar OpenCode a otra versión mayor.";
assert lib.assertMsg (
  lib.hasInfix "$out/bin/opencode2" upstream.installPhase
  && lib.hasInfix "--prefix PATH" upstream.installPhase
  && lib.hasInfix "$out/bin/.opencode2-wrapped" upstream.postFixup
) "Cambió el empaquetado de llm-agents.opencode2; revisar la adaptación local.";
upstream.overrideAttrs (old: {
  pname = "opencode";
  nativeBuildInputs = old.nativeBuildInputs ++ [ installShellFiles ];
  installPhase =
    lib.replaceStrings
      [ "opencode2" "--prefix PATH" ]
      [ "opencode" "--set OPENCODE_DISABLE_AUTOUPDATE true --prefix PATH" ]
      old.installPhase;
  postFixup = lib.replaceStrings [ "opencode2" ] [ "opencode" ] old.postFixup;
  # auto-formatelf repara el intérprete en postFixupHooks: ejecutar el binario
  # después de esos hooks, no en postFixup, para no depender de nix-ld del host.
  postInstallCheck =
    (old.postInstallCheck or "")
    + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      export HOME="$(mktemp -d)"
      export XDG_CONFIG_HOME="$HOME/.config"
      export XDG_DATA_HOME="$HOME/.local/share"
      export XDG_STATE_HOME="$HOME/.local/state"
      export XDG_CACHE_HOME="$HOME/.cache"
      installShellCompletion --cmd opencode \
        --bash <($out/bin/opencode --completions bash) \
        --zsh <($out/bin/opencode --completions zsh) \
        --fish <($out/bin/opencode --completions fish)
    '';
  meta = old.meta // {
    mainProgram = "opencode";
  };
})
