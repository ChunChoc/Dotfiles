{ pkgs, lib, osConfig, ... }:

{
  # Laboratorio de redes. Va aquí y no en modules/features porque solo son
  # apps de usuario: no toca firewall, servicios ni kernel.
  #
  # Cisco Packet Tracer es unfree y su instalador está detrás del login de
  # NetAcad, así que nixpkgs lo declara con `requireFile`: no se descarga
  # solo, hay que meter el .deb al store a mano (una vez por versión):
  #
  #   nix-store --add-fixed sha256 ~/Downloads/CiscoPacketTracer_901_Ubuntu_64bit.deb
  #
  # El .deb sale de https://www.netacad.com/resources/lab-downloads. Si falta,
  # la compilación falla con ese mismo mensaje; el resto del sistema no se ve
  # afectado mientras `networkLab` esté en false.
  config = lib.mkIf osConfig.myFeatures.networkLab {
    home.packages = [ pkgs.ciscoPacketTracer9 ];
  };
}
