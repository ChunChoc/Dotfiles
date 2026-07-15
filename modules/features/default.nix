{ ... }:

{
  # Agregador: se importan TODOS los features. Cada uno está protegido con
  # `lib.mkIf config.myFeatures.X`, así que cada host solo activa los flags
  # que necesita en su default.nix (una única fuente de verdad).
  # Features que solo instalan paquetes de usuario (communication, office)
  # viven en modules/home leyendo estos mismos flags vía osConfig.
  imports = [
    ./battery-charge-limit.nix
    ./development.nix
    ./gaming.nix
    ./localsend.nix
    ./virtualization.nix
  ];
}
