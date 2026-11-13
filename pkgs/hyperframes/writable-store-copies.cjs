"use strict";
// Preload de la CLI de HyperFrames en Nix: las plantillas viven en /nix/store (0444/0555)
// y fs.copyFile*/cp conservan esos permisos, así que `hyperframes init` no podía editar
// después el index.html que acababa de copiar (EACCES). Tras copiar algo que viene del
// store, se le da escritura al dueño. El resto de copias no se toca.
const fs = require("node:fs");
const path = require("node:path");
const { syncBuiltinESMExports } = require("node:module");

const STORE = "/nix/store/";

function toPath(p) {
  return p instanceof URL ? p.pathname : String(p);
}

function fromStore(src) {
  try {
    return path.resolve(toPath(src)).startsWith(STORE);
  } catch {
    return false;
  }
}

function makeWritable(target) {
  try {
    const st = fs.lstatSync(target);
    if (st.isSymbolicLink()) return;
    if ((st.mode & 0o200) === 0) fs.chmodSync(target, st.mode | 0o200);
    if (st.isDirectory()) {
      for (const entry of fs.readdirSync(target)) makeWritable(path.join(target, entry));
    }
  } catch {
    // Mejor esfuerzo: nunca romper la copia original.
  }
}

for (const name of ["copyFileSync", "cpSync"]) {
  const original = fs[name];
  fs[name] = function (src, dest, ...rest) {
    const result = original.call(this, src, dest, ...rest);
    if (fromStore(src)) makeWritable(toPath(dest));
    return result;
  };
}

for (const name of ["copyFile", "cp"]) {
  const original = fs.promises[name];
  fs.promises[name] = async function (src, dest, ...rest) {
    const result = await original.call(this, src, dest, ...rest);
    if (fromStore(src)) makeWritable(toPath(dest));
    return result;
  };
}

// Propaga los reemplazos a los `import { copyFileSync } from "node:fs"` de los módulos ESM.
syncBuiltinESMExports();
