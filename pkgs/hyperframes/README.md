# hyperframes

CLI de [HyperFrames](https://github.com/heygen-com/hyperframes) + sus skills para agentes,
activados con `myFeatures.hyperframes` (módulo `modules/home/programs/hyperframes.nix`).

| Archivo | Qué hace |
| --- | --- |
| `default.nix` | CLI desde el tarball de npm con `package-lock.json` fijado; wrapper con Chrome headless, FFmpeg, whisper-cpp y Python/Kokoro de nixpkgs. |
| `kokoro-python.nix` | Python con `kokoro-onnx` para `hyperframes tts`; `espeakng-loader` reemplazado por uno que apunta a `espeak-ng` de nixpkgs. |
| `writable-store-copies.cjs` | Preload de Node: lo que la CLI copia desde `/nix/store` (plantillas) queda escribible. |
| `skills.nix` | Skills del input `hyperframes` del flake, con `npx hyperframes` → `hyperframes` y una nota de entorno Nix. |

## Actualizar a una versión nueva

La CLI y las skills deben ser la misma release (`skills.nix` falla al evaluar si no).

1. En `flake.nix`, cambiar el tag del input: `github:heygen-com/hyperframes/vX.Y.Z`, y `nix flake lock --update-input hyperframes`.
2. En `default.nix`, cambiar `version` y poner `hash = lib.fakeHash;` (el build muestra el hash real).
3. Regenerar el lockfile, en un directorio temporal:

   ```sh
   curl -sL https://registry.npmjs.org/hyperframes/-/hyperframes-X.Y.Z.tgz | tar xz
   cd package
   nix shell nixpkgs#nodejs_22 nixpkgs#jq -c sh -c \
     'jq "del(.devDependencies, .scripts)" package.json > p.json && mv p.json package.json &&
      npm install --package-lock-only --ignore-scripts --no-audit --no-fund'
   cp package-lock.json ~/Dotfiles/pkgs/hyperframes/
   ```

4. Poner `npmDepsHash = lib.fakeHash;`, construir y copiar el hash real.
5. Si `substituteInPlace` del `init-*.js` falla, upstream cambió cómo genera los scripts del
   `package.json`: revisar `packages/cli/src/commands/init.ts` (función con `npx --yes`).
6. Probar: `hyperframes doctor`, `hyperframes init x && cd x && bun run render`.
