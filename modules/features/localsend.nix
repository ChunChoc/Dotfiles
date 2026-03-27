{ config, lib, ... }:

{
  config = lib.mkIf config.myFeatures.localsend {
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };
  };
}
