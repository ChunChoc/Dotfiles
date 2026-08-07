{ config, pkgs, ... }:

{
  # --------------------------------------------------------
  # Música: MPD (daemon) + rmpc (cliente TUI)
  # --------------------------------------------------------
  # Reemplaza a Tauon. El modelo es distinto: MPD es un servicio que mantiene la
  # biblioteca y la reproducción, y el cliente es desechable —puedes cerrar rmpc
  # y la música sigue—. La cola, el estado y la posición viven en el daemon.

  services.mpd = {
    enable = true;
    # musicDirectory sale de xdg.userDirs.music (~/Music) automáticamente.
    # network.listenAddress ya es 127.0.0.1 por defecto: nada expuesto a la red.

    extraConfig = ''
      # --- Salida ---
      # Por PipeWire, no por ALSA. MPD queda como un cliente más del servidor de
      # audio, exactamente igual que el navegador o una llamada: comparte la
      # tarjeta, respeta el sink por defecto y sigue los cambios de dispositivo
      # (enchufar los Moondrop MAY conmuta la salida solo). Un output ALSA
      # directo sonaría "más puro" en teoría pero toma la tarjeta en exclusiva y
      # es justo lo que rompe el audio de las llamadas.
      audio_output {
          type  "pipewire"
          name  "PipeWire"
      }

      # Sin audio_output_format: MPD entrega el stream tal cual viene del archivo
      # y no remuestrea nada. Quien decide el rate final es PipeWire (ver
      # default.clock.allowed-rates en modules/desktop.nix).

      # El volumen lo aplica PipeWire sobre el stream, no MPD sobre las muestras:
      # así subirle o bajarle desde rmpc no cuesta bits de resolución.
      mixer_type "hardware"

      # --- Comportamiento ---
      # inotify sobre ~/Music: los archivos nuevos entran a la biblioteca solos.
      auto_update "yes"
      # Al iniciar sesión no arranca a sonar de la nada.
      restore_paused "yes"
      # Nada de anunciar el servidor por Avahi en la red local.
      zeroconf_enabled "no"
    '';
  };

  # Puente MPD -> MPRIS. Sin esto MPD es invisible para el escritorio: DMS no lo
  # muestra en la barra y las teclas de medios (XF86AudioPlay y compañía, que en
  # binds.kdl llaman a `dms ipc call mpris ...`) no lo controlan.
  services.mpd-mpris.enable = true;

  # rmpc: cliente TUI. El servicio de MPD ya instala el paquete `mpd` (que trae
  # `mpc` para scripting), así que aquí solo falta el cliente.
  home.packages = [ pkgs.rmpc ];

  xdg.configFile = {
    "rmpc/config.ron".source = ../dotfiles/rmpc/config.ron;
    "rmpc/themes/catppuccin-mocha.ron".source = ../dotfiles/rmpc/themes/catppuccin-mocha.ron;
  };
}
