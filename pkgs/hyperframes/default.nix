{
  lib,
  stdenv,
  buildNpmPackage,
  fetchurl,
  jq,
  nodejs_22,
  makeWrapper,
  autoPatchelfHook,
  callPackage,
  ffmpeg,
  whisper-cpp,
  unzip,
  playwright-driver,
}:

# CLI de HyperFrames (https://github.com/heygen-com/hyperframes) empaquetada desde
# el tarball de npm con un package-lock fijado. `version` debe coincidir con el tag
# del input `hyperframes` del flake (skills.nix lo verifica al evaluar).
# Para actualizar, ver README.md de esta carpeta.
let
  pname = "hyperframes";
  version = "0.9.39";

  kokoroPython = callPackage ./kokoro-python.nix { };

  # chrome-headless-shell parcheado por nixpkgs: el que descarga la CLI
  # (~/.cache/puppeteer) es un binario dinámico que no corre en NixOS.
  headlessShell = "${playwright-driver.components.chromium-headless-shell}/chrome-headless-shell-linux64/chrome-headless-shell";

  # Entorno que necesita la CLI. Lo aplica el wrapper y, además, Home Manager lo
  # exporta en la sesión: los scripts de las skills (media-use) lanzan la CLI vía
  # HYPERFRAMES_CLI_ENTRY con `node`, sin pasar por el wrapper.
  env = cli: {
    HYPERFRAMES_CLI_ENTRY = "${cli}/lib/node_modules/hyperframes/bin/hyperframes.mjs";
    HYPERFRAMES_BROWSER_PATH = headlessShell;
    HYPERFRAMES_FFMPEG_PATH = lib.getExe' ffmpeg "ffmpeg";
    HYPERFRAMES_FFPROBE_PATH = lib.getExe' ffmpeg "ffprobe";
    HYPERFRAMES_WHISPER_PATH = lib.getExe' whisper-cpp "whisper-cli";
    HYPERFRAMES_PYTHON = "${kokoroPython}/bin/python3";
    # Versión, skills y navegador los gestiona Nix: nada de auto-actualizar ni descargar.
    HYPERFRAMES_NO_UPDATE_CHECK = "1";
    HYPERFRAMES_NO_AUTO_INSTALL = "1";
    HYPERFRAMES_SKIP_SKILLS = "1";
    HYPERFRAMES_NO_TELEMETRY = "1";
  };
in
buildNpmPackage (finalAttrs: {
  inherit pname version;

  src = fetchurl {
    url = "https://registry.npmjs.org/hyperframes/-/hyperframes-${version}.tgz";
    hash = "sha256-8QinkeVpbjLWZOiMSd3Q1JeXDJU5M1piAtqfbV54eFg=";
  };
  sourceRoot = "package";

  nodejs = nodejs_22;
  npmDepsHash = "sha256-lvSXeQFIILddjDemYzwVSQBWmJxiWVi3m9NKw36TMGo=";

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];
  # sharp (opcional, para imágenes) trae .node precompilados que necesitan libstdc++.
  buildInputs = [ stdenv.cc.cc.lib ];

  # El package.json publicado conserva devDependencies `workspace:*` del monorepo.
  # postPatch también corre dentro de fetchNpmDeps, por eso jq va por ruta absoluta.
  postPatch = ''
    ${lib.getExe jq} 'del(.devDependencies, .scripts)' package.json > package.json.new
    mv package.json.new package.json
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;
  npmRebuildFlags = [ "--ignore-scripts" ];

  postInstall = ''
    root="$out/lib/node_modules/hyperframes"

    # npm instala también las variantes musl de sharp; en glibc sobran.
    rm -rf "$root"/node_modules/@img/*linuxmusl*

    # `init` escribe scripts "npx --yes hyperframes@<v> ..." en el package.json del
    # proyecto; npx/bunx bajarían otra copia de npm. Se usa la CLI del PATH, así
    # `bun run render` y `npm run render` corren esta misma versión.
    substituteInPlace "$root"/dist/init-*.js \
      --replace-fail 'npx --yes ''${getHyperframesPackageSpecifier()} ''${command}' 'hyperframes ''${command}'

    for bin in hyperframes hyperframes-localize-fonts; do
      wrapProgram "$out/bin/$bin" \
        --prefix PATH : ${lib.makeBinPath [ ffmpeg whisper-cpp unzip ]} \
        --prefix NODE_OPTIONS " " "--require=${./writable-store-copies.cjs}" \
        ${lib.concatStringsSep " " (
          lib.mapAttrsToList (k: v: "--set-default ${k} ${lib.escapeShellArg v}") (env (placeholder "out"))
        )}
    done
  '';

  passthru = {
    inherit kokoroPython headlessShell;
    env = env finalAttrs.finalPackage;
  };

  meta = {
    description = "Write HTML, render video — HyperFrames CLI by HeyGen";
    homepage = "https://hyperframes.heygen.com";
    license = lib.licenses.asl20;
    mainProgram = "hyperframes";
    platforms = [ "x86_64-linux" ];
  };
})
