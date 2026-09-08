{ ... }:

{
  # Agregador del feature gaming. Cada submódulo se protege con su propio
  # flag (`myFeatures.gaming.*`), así que importar esto NO enciende nada:
  # el host elige qué mitad quiere.
  #
  # Minecraft no aparece aquí porque Prism Launcher es solo un paquete de
  # usuario: vive en modules/home/packages.nix leyendo el flag
  # `myFeatures.gaming.minecraft` vía osConfig (regla de AGENTS.md, nada de
  # home-manager.users.* desde modules/features).
  imports = [
    ./steam.nix
  ];
}
