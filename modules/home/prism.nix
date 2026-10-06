{ config, pkgs, lib, osConfig, ... }:

let
  # Rutas fijas a los JDK que el envoltorio de nixpkgs le pasa a Prism
  # (PRISMLAUNCHER_JAVA_PATHS): mismas derivaciones, así que no ocupan nada
  # extra en el store.
  javaDir = "${config.xdg.dataHome}/PrismLauncher/nix-jdk";
  jdks = {
    "8" = pkgs.jdk8;
    "17" = pkgs.jdk17;
    "21" = pkgs.jdk21;
    "25" = pkgs.jdk25;
  };
  versions = lib.concatStringsSep "|" (builtins.attrNames jdks);
in
{
  # Prism guarda la ruta de Java tal cual la elegiste, y en NixOS esa ruta es
  # /nix/store/<hash>-openjdk-…: cada update de nixpkgs cambia el hash y el GC
  # semanal borra la vieja. Prism ve que el Java configurado ya no existe y
  # vuelve a abrir el asistente de configuración rápida (y las instancias con
  # Java propio dejan de arrancar). Visto el 2026-10-05.
  #
  # Arreglo: enlaces estables nix-jdk/<versión> que siguen al JDK vigente, y en
  # cada switch se reescriben a ellos las rutas del store que Prism haya
  # guardado (global e instancias), antes de que el GC las borre.
  config = lib.mkIf osConfig.myFeatures.gaming.minecraft {
    xdg.dataFile = lib.mapAttrs' (v: jdk:
      lib.nameValuePair "PrismLauncher/nix-jdk/${v}" { source = jdk; }
    ) jdks;

    home.activation.prismStableJava = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      data=${lib.escapeShellArg "${config.xdg.dataHome}/PrismLauncher"}
      for f in "$data/prismlauncher.cfg" "$data"/instances/*/instance.cfg; do
        [ -f "$f" ] || continue
        if ${pkgs.gnugrep}/bin/grep -qE '^JavaPath=/nix/store/' "$f"; then
          run ${pkgs.gnused}/bin/sed -i -E \
            's#^JavaPath=/nix/store/[^/]*-openjdk-(${versions})(u|\.)[^/]*/bin/java$#JavaPath=${javaDir}/\1/bin/java#' \
            "$f"
        fi
      done
    '';
  };
}
