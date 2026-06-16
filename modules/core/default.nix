{ ... }:

{
  # Agregador: módulos base presentes en todos los hosts.
  imports = [
    ./bootloader.nix
    ./fonts.nix
    ./system.nix
    ./user.nix
  ];
}
