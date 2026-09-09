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

    # gamemode NO se activa solo: se pide por juego, en las opciones de
    # lanzamiento de Steam:
    #
    #   gamemoderun %command%
    #
    # Ahí ajusta el governor del CPU mientras dura la partida y restaura el
    # que había al salir. No habla con power-profiles-daemon (el "plan de
    # energía" de la barra de DMS): escribe el governor directo, así que
    # durante el juego la barra sigue mostrando el perfil viejo. Es cosmético
    # —ver gamemode#462—, pero si se cambia el perfil en DMS con el juego
    # corriendo, al cerrarlo gamemode pisa ese cambio.
    #
    # Ojo con la expectativa: en este equipo casi nunca va a poner
    # "performance". Con `igpu_desiredgov=powersave` y umbral 0.3, cuando
    # detecta que la carga la lleva la iGPU baja el CPU a powersave para
    # dejarle a la UHD 620 más del presupuesto de 15 W que comparte con el
    # i5-8250U. Eso es justo lo que más FPS da en un chip U.
    programs.gamemode.enable = true;

    # gamescope tampoco es automático: es un compositor anidado que se invoca
    # por juego. Lo que más rinde en una UHD 620 es renderizar a 720p y
    # escalar a la pantalla, también desde las opciones de lanzamiento:
    #
    #   gamescope -W 1920 -H 1080 -w 1280 -h 720 -f -- gamemoderun %command%
    programs.gamescope.enable = true;
  };
}
