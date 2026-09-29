{ pkgs, lib, monitorSettings, externalOutputs, ... }:

let
  # --------------------------------------------------------
  # Proyectores: duplicar la pantalla, como Windows
  # --------------------------------------------------------
  # niri no duplica pantallas: toda salida nueva es escritorio extendido y,
  # si no tiene bloque `output` en la config, usa el modo que la pantalla
  # marca como preferido en su EDID. Un Epson de aula anunció 800x600, así
  # que salió un escritorio 4:3 diminuto a la derecha (log de niri,
  # 2026-09-29).
  #
  # Regla: toda salida externa que NO esté en `externalOutputs` (flake.nix)
  # se trata como proyector.
  # 1. Se pone en su mejor modo: el tamaño del panel de la laptop si lo tiene;
  #    si no, el más grande que no pase de ese ancho.
  # 2. Se duplica con wl-mirror a pantalla completa. La salida se aparta a
  #    una posición lejana y sin vecinos para que el cursor no se escape a
  #    ella.
  # Los monitores conocidos (el AOC) quedan como siempre, aparte.
  #
  # Mod+P (binds.kdl) alterna entre duplicar y extender. Al desconectar se
  # vuelve a duplicar para la próxima vez.
  laptop = monitorSettings.name;
  knownOutputs = builtins.toJSON (map (o: o.name) externalOutputs);
  laptopWidth = toString monitorSettings.width;
  laptopHeight = toString monitorSettings.height;
  # A la derecha del panel en coordenadas lógicas, igual que el AOC.
  extendX = toString (builtins.ceil (monitorSettings.width / monitorSettings.scale));

  niriProjector = pkgs.writeShellApplication {
    name = "niri-projector";
    runtimeInputs = [
      pkgs.jq
      pkgs.util-linux # flock
      pkgs.wl-mirror
    ];
    # `niri` sale del PATH de la sesión: tiene que ser el mismo binario que el
    # compositor en marcha para que el IPC coincida.
    text = ''
      state="''${XDG_RUNTIME_DIR:?}/niri-projector"
      mirror_unit=niri-projector-mirror

      # Primera salida externa que no es un monitor conocido. niri identifica
      # la pantalla como "marca modelo serie" (serie "Unknown" si no la tiene),
      # que es el formato de externalOutputs.
      find_projector() {
        niri msg --json outputs | jq -r \
          --arg laptop ${lib.escapeShellArg laptop} \
          --argjson known ${lib.escapeShellArg knownOutputs} '
          [ .[]
            | select(.name != $laptop)
            | .name as $conn
            | select(([.make, .model, (.serial // "Unknown")] | join(" ")) as $id
                | ($known | index($id)) == null and ($known | index($conn)) == null)
          ] | first // empty | .name'
      }

      # "WxH@R" del mejor modo e índice actual, en una línea.
      best_mode() {
        niri msg --json outputs | jq -r --arg name "$1" \
          --argjson w ${laptopWidth} --argjson h ${laptopHeight} '
          .[$name]
          | [.modes | to_entries[] | .value + {i: .key}] as $m
          # Tamaño del panel si existe; si no, el mayor con ancho <= panel
          # (evita 4K a 30 Hz); si tampoco, el mayor de todos.
          | [$m[] | select(.width == $w and .height == $h)] as $exact
          | ([$m[] | select(.width <= $w)] | if length > 0 then . else $m end) as $fit
          | (if ($exact | length) > 0 then $exact
             else ($fit | max_by(.width * .height)) as $b
               | [$fit[] | select(.width == $b.width and .height == $b.height)]
             end) as $size
          # Refresco: el más alto hasta ~60 Hz (los proyectores van a 60).
          | (([$size[] | select(.refresh_rate <= 60500)] | max_by(.refresh_rate))
             // ($size | min_by(.refresh_rate)))
          | select(. != null)
          | "\(.width)x\(.height)@\(.refresh_rate / 1000) \(.i)"
        ' | awk -v cur="$2" '{ print $1, ($2 == cur ? "same" : "change") }'
      }

      apply() {
        local out info mode change cur x
        out="$(find_projector)"
        if [ -z "$out" ]; then
          systemctl --user stop "$mirror_unit" 2>/dev/null || true
          rm -f "$state"
          return 0
        fi

        info="$(niri msg --json outputs | jq -r --arg n "$out" \
          '.[$n] | "\(.current_mode // -1) \(.logical.x // 0)"')"
        cur="''${info% *}"
        x="''${info#* }"

        mode="" change=""
        read -r mode change < <(best_mode "$out" "$cur") || true
        if [ "$change" = change ]; then
          niri msg output "$out" mode "$mode"
        fi

        if [ "$(cat "$state" 2>/dev/null || echo mirror)" = mirror ]; then
          # Lejos y sin vecinos: el cursor no puede cruzar a ella.
          [ "$x" = 100000 ] || niri msg output "$out" position set 100000 0
          if ! systemctl --user is-active --quiet "$mirror_unit"; then
            systemd-run --user --quiet --collect --unit="$mirror_unit" \
              -p BindsTo=niri-projector.service -p After=niri-projector.service \
              wl-mirror --fullscreen-output "$out" ${lib.escapeShellArg laptop}
          fi
        else
          systemctl --user stop "$mirror_unit" 2>/dev/null || true
          [ "$x" = ${extendX} ] || niri msg output "$out" position set ${extendX} 0
        fi
      }

      locked_apply() {
        exec 9>"$state.lock"
        flock 9
        apply
        exec 9>&-
      }

      case "''${1:-watch}" in
        toggle)
          if [ "$(cat "$state" 2>/dev/null || echo mirror)" = mirror ]; then
            echo extend > "$state"
          else
            echo mirror > "$state"
          fi
          locked_apply
          ;;
        watch)
          # niri no emite eventos de salidas, pero conectar o quitar una
          # pantalla siempre reparte workspaces, y apply es idempotente.
          niri msg --json event-stream | while read -r line; do
            case "$line" in
              '{"WorkspacesChanged"'*) locked_apply ;;
            esac
          done
          ;;
        *)
          echo "uso: niri-projector [watch|toggle]" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  home.packages = [ niriProjector ];

  systemd.user.services.niri-projector = {
    Unit = {
      Description = "Duplicar la pantalla en proyectores (salidas desconocidas)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${niriProjector}/bin/niri-projector watch";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
