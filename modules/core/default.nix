{ ... }:

{
  # Agregador: módulos base presentes en todos los hosts.
  imports = [
    ./bootloader.nix
    ./system.nix
    ./user.nix
  ];
}
