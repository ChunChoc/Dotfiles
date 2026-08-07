{ config, pkgs, ... }:

let
  # Tus FLAC ya traen la letra sincronizada, pero embebida en el tag LYRICS, y
  # rmpc solo lee archivos .lrc sueltos (no toca tags: en su binario no existe
  # ni USLT, ni SYLT, ni UNSYNCEDLYRICS). Este script hace el puente: vuelca el
  # tag a ~/.local/share/rmpc/lyrics espejando la estructura de ~/Music, que es
  # como rmpc resuelve la ruta. Correlo cuando agregues música.
  syncLyrics = pkgs.writeShellApplication {
    name = "rmpc-sync-lyrics";
    runtimeInputs = [ pkgs.flac pkgs.coreutils pkgs.findutils pkgs.gnused pkgs.gnugrep ];
    text = ''
      music_dir="''${XDG_MUSIC_DIR:-$HOME/Music}"
      lyrics_dir="$HOME/.local/share/rmpc/lyrics"

      written=0
      unsynced=0
      missing=0

      while IFS= read -r -d ''' file; do
        rel="''${file#"$music_dir"/}"
        lrc="$lyrics_dir/''${rel%.*}.lrc"

        raw="$(metaflac --show-tag=LYRICS "$file" 2>/dev/null | sed '1s/^LYRICS=//')"
        if [ -z "$raw" ]; then
          missing=$((missing + 1))
          printf 'sin letra: %s\n' "$rel" >&2
          continue
        fi

        # rmpc solo soporta letra sincronizada. Sin marcas de tiempo no la
        # dibujaría, así que mejor no generar el archivo y decirlo.
        if ! printf '%s' "$raw" | grep -qE '^\[[0-9]+:[0-9]+'; then
          unsynced=$((unsynced + 1))
          printf 'letra sin sincronizar (rmpc no la muestra): %s\n' "$rel" >&2
          continue
        fi

        mkdir -p "$(dirname "$lrc")"
        {
          # Cabeceras LRC: rmpc las usa para su índice, que es el plan B
          # cuando la ruta no coincide.
          for tag in ar:ARTIST ti:TITLE al:ALBUM; do
            value="$(metaflac --show-tag="''${tag#*:}" "$file" 2>/dev/null | sed '1s/^[^=]*=//')"
            [ -n "$value" ] && printf '[%s:%s]\n' "''${tag%%:*}" "$value"
          done
          printf '%s\n' "$raw"
        } > "$lrc"
        written=$((written + 1))
      done < <(find "$music_dir" -type f -iname '*.flac' -print0)

      printf '\n%s letras escritas en %s\n' "$written" "$lyrics_dir"
      [ "$unsynced" -gt 0 ] && printf '%s sin sincronizar (omitidas)\n' "$unsynced"
      [ "$missing" -gt 0 ] && printf '%s sin tag LYRICS\n' "$missing"
      exit 0
    '';
  };
in

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

      # Copia del audio a un FIFO para el visualizador de rmpc (que por dentro
      # es cava). MPD alimenta las dos salidas a la vez y el `format` de aquí
      # solo aplica a esta: la de PipeWire sigue recibiendo el stream nativo,
      # así que el visualizador no cuesta nada en calidad. Si nadie lee el FIFO
      # (rmpc cerrado), MPD simplemente descarta lo que escribe.
      # El formato tiene que coincidir con cava.input en rmpc/config.ron.
      audio_output {
          type    "fifo"
          name    "Visualizer"
          path    "/tmp/mpd.fifo"
          format  "44100:16:2"
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
  home.packages = [
    pkgs.rmpc
    syncLyrics
  ];

  xdg.configFile = {
    "rmpc/config.ron".source = ../dotfiles/rmpc/config.ron;
    "rmpc/themes/catppuccin-mocha.ron".source = ../dotfiles/rmpc/themes/catppuccin-mocha.ron;
  };
}
