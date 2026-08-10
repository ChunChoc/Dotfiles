{ pkgs, ... }:

let
  # --------------------------------------------------------
  # Por qué existe esto
  # --------------------------------------------------------
  # Cuando niri copia una captura al portapapeles, la oferta Wayland lleva un
  # solo tipo: `image/png`. Medido con `wl-paste --list-types`.
  #
  # Eso basta para clientes Wayland de verdad (Signal, LibreOffice), que piden
  # `image/png` directamente. Pero la terminal es un tubo de texto: el
  # Ctrl+Shift+V de Ghostty pide `text/plain`, no encuentra nada, y no pega
  # nada. Por eso las capturas no entraban en Claude ni en opencode.
  #
  # El rodeo que funcionaba a mano era abrir el portapapeles de DMS y
  # reseleccionar la imagen. No es casualidad: DMS guarda cada entrada en
  # ~/.cache/dms/clipboard y al re-copiarla ofrece cuatro tipos —
  # `x-special/gnome-copied-files`, `text/uri-list`, `text/plain` e
  # `image/png`—, donde el texto es la ruta del PNG. Ahí Ctrl+Shift+V sí tiene
  # algo que pegar (la ruta) y el TUI abre el archivo.
  #
  # Este servicio automatiza exactamente ese paso, sin inventar nada: escucha
  # el portapapeles y, cuando aparece una entrada que es SOLO imagen, le pide a
  # DMS que la vuelva a copiar. El `image/png` se conserva, así que Signal y
  # LibreOffice siguen igual; lo único que se gana es el texto.
  #
  # No se cicla: la re-copia ya lleva `text/plain`, así que deja de cumplir la
  # condición. Y como cubre el portapapeles entero y no solo las capturas,
  # también arregla el "copiar imagen" de Brave o de cualquier otra app.
  #
  # Alternativa descartada: poner la ruta con `wl-copy`. Solo sabe ofrecer un
  # tipo por invocación, así que sustituiría la imagen por texto y rompería el
  # pegado en Signal. `dms clipboard get --copy` es la única herramienta que ya
  # ofrece los dos a la vez.
  reoffer = pkgs.writeShellScript "clipboard-images-reoffer" ''
    set -u

    dms="${pkgs.dms-shell}/bin/dms"

    # `--mimes` añade el array `mimeTypes`; el filtro dispara solo cuando TODOS
    # los tipos ofrecidos son imagen, que es la firma de la copia de niri. Si
    # DMS cambiara el formato del JSON, jq deja de emitir y esto simplemente no
    # hace nada: no puede romper el portapapeles.
    "$dms" clipboard watch --json --mimes \
      | ${pkgs.jq}/bin/jq --unbuffered -r '
          select((.mimeTypes | length) > 0 and (.mimeTypes | all(startswith("image/"))))
          | "reoffer"
        ' \
      | while IFS= read -r _; do
          # El servidor de DMS registra la entrada de forma asíncrona, así que
          # puede no estar todavía en el historial cuando llega el evento. Se
          # reintenta hasta 2 s; si en ese rato la más reciente no es una
          # imagen, se abandona en vez de re-copiar cualquier otra cosa.
          for _ in 1 2 3 4 5 6 7 8 9 10; do
            entry="$("$dms" clipboard history 2>/dev/null | ${pkgs.gnugrep}/bin/grep -m1 '^ID: ')" || entry=""

            case "$entry" in
              *"| image |"*)
                id="''${entry#ID: }"
                id="''${id%% *}"
                "$dms" clipboard get "$id" --copy >/dev/null 2>&1 || true
                break
                ;;
            esac

            sleep 0.2
          done
        done
  '';
in

{
  systemd.user.services.clipboard-images = {
    Unit = {
      Description = "Re-ofrecer las imágenes del portapapeles con su ruta en texto";
      After = [
        "graphical-session.target"
        "dms.service"
      ];
      # `dms clipboard watch` y `dms clipboard get --copy` hablan con el
      # servidor de DMS: sin él no hay nada que hacer.
      BindsTo = [ "dms.service" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${reoffer}";
      # Si DMS se reinicia, el watch muere con él y vuelve a engancharse.
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
