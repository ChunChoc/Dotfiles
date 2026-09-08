{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.myFeatures.gaming.steam {
    programs.steam = {
      enable = true;

      # Proton-GE cubre títulos que el Proton oficial no arregla todavía.
      # Al ser declarativo no hay que andar bajándolo con ProtonUp.
      extraCompatPackages = [ pkgs.proton-ge-bin ];

      # Para tocar el prefix Wine de un juego (fuentes, DLLs, dxvk) sin
      # inventar rutas a mano dentro de ~/.steam.
      protontricks.enable = true;

      # Puertos cerrados por defecto: esta máquina no hostea servidores ni
      # hace Remote Play. Poner en true solo si algún día se ocupa.
      remotePlay.openFirewall = false;
      dedicatedServer.openFirewall = false;
      localNetworkGameTransfers.openFirewall = false;
    };

    # Proton y casi todo el catálogo viejo siguen siendo 32-bit.
    hardware.graphics.enable32Bit = true;

    # El i5-8250U es un chip U de 15 W: sin gamemode el governor se queda en
    # powersave y el juego arranca a media frecuencia. gamemode lo sube a
    # performance solo mientras el juego corre.
    programs.gamemode.enable = true;

    # gamescope es la palanca que más rinde en una UHD 620: deja renderizar
    # el juego a 720p y escalarlo a la pantalla 1080p. Se usa por juego, en
    # las opciones de lanzamiento de Steam:
    #   gamescope -W 1920 -H 1080 -w 1280 -h 720 -f -- %command%
    programs.gamescope.enable = true;
  };
}
