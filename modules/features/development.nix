{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.myFeatures.development {
    # Paquetes de desarrollo a nivel sistema (si los hay)
    # Por ahora los paquetes de usuario se manejan en home/packages.nix

    # Ejemplo de paquetes de sistema para desarrollo:
    # environment.systemPackages = with pkgs; [
    #   git
    #   gcc
    #   gnumake
    # ];
  };
}
