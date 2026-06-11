{ ... }:

{
  # Agregador: se importan TODOS los features. Cada uno está protegido con
  # `lib.mkIf config.myFeatures.X`, así que cada host solo activa los flags
  # que necesita en su default.nix (una única fuente de verdad).
  imports = [
    ./communication.nix
    ./development.nix
    ./gaming.nix
    ./localsend.nix
    ./office.nix
    ./virtualization.nix
  ];
}
