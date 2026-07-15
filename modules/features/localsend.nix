{ config, lib, ... }:

{
  config = lib.mkIf config.myFeatures.localsend {
    # Solo abre los puertos; el firewall se habilita en modules/core/system.nix
    # y la app se instala en modules/home/localsend.nix con el mismo flag.
    networking.firewall = {
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };
  };
}
