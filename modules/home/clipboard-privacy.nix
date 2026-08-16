{ pkgs, ... }:

let
  # --------------------------------------------------------
  # Por qué existe esto
  # --------------------------------------------------------
  # El historial del portapapeles de DMS vive en
  # ~/.cache/DankMaterialShell/clipboard/db, en texto plano. El disco está
  # cifrado con LUKS, así que apagada la máquina no hay problema; el riesgo es
  # con la sesión abierta, donde cualquier proceso corriendo como este usuario
  # lo puede leer. Lo que se busca es acortar cuánto tiempo existe cada copia.
  #
  # Con los valores de fábrica (maxHistory 100, autoClearDays 0) nada caduca
  # por tiempo: la entrada 101 empuja a la más vieja y ya. Medido, eso daba una
  # retención real de ~6 días, de ahí que al encender la laptop siguiera ahí lo
  # copiado el día anterior.
  #
  # Detalle importante que estos números NO arreglan: DMS ignora las copias
  # marcadas con `x-kde-passwordManagerHint` (tiene `hasSensitiveMimeType`),
  # pero eso solo sirve si la app que copia pone la marca. Proton Pass se usa
  # aquí como extensión de Brave, y las extensiones copian por la API del
  # navegador, que no la pone. Su temporizador de "borrar el portapapeles"
  # limpia la selección viva, no el historial que DMS ya guardó. La defensa de
  # verdad es usar el autorrelleno en vez de copiar; esto solo acota el daño.
  #
  # Esta config vive dentro de la base del servidor, no en settings.json, así
  # que no hay forma declarativa nativa. Se reaplica en cada arranque de sesión
  # y así el repo sigue siendo la fuente de verdad.
  applyClipboardPolicy = pkgs.writeShellScript "dms-clipboard-policy" ''
    set -eu

    dms="${pkgs.dms-shell}/bin/dms"

    # El servidor de DMS puede no estar escuchando todavía cuando esto corre.
    # Se reintenta ~10 s; si no aparece, se sale sin error para no dejar la
    # unidad en failed por algo que no es crítico.
    for _ in $(seq 1 20); do
      if "$dms" clipboard config get >/dev/null 2>&1; then
        "$dms" clipboard config set \
          --max-history 50 \
          --auto-clear-days 1 \
          --clear-at-startup
        exit 0
      fi

      sleep 0.5
    done
  '';
in

{
  systemd.user.services.dms-clipboard-policy = {
    Unit = {
      Description = "Aplicar la política de retención del portapapeles de DMS";
      After = [
        "graphical-session.target"
        "dms.service"
      ];
      BindsTo = [ "dms.service" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${applyClipboardPolicy}";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
