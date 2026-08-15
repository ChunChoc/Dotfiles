{ config, lib, pkgs, ... }:

{
  # --------------------------------------------------------
  # Ghostty (terminal GTK4) — la terminal del sistema
  # --------------------------------------------------------
  # Reemplazó a Alacritty; colores y fuente son los que tenía aquel.
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      # Tema que ya trae el paquete en share/ghostty/themes
      theme = "Catppuccin Mocha";
      font-family = "JetBrainsMono Nerd Font";
      font-size = 11;

      # El tema de Ghostty usa el acento rosewater/pink; el resto del sistema
      # (DMS, nvim, la config que traía Alacritty) es Catppuccin Mocha *Mauve*.
      cursor-color = "#cba6f7";
      cursor-text = "#1e1e2e";
      selection-background = "#cba6f7";
      selection-foreground = "#1e1e2e";
      palette = [
        # magenta normal y brillante -> mauve en vez de pink
        "5=#cba6f7"
        "13=#cba6f7"
        # extendidos que Catppuccin define y el tema del paquete omite
        "16=#fab387"
        "17=#f5e0dc"
      ];
      # Estela del cursor, como el cursor_trail de Kitty. Ghostty no tiene
      # animaciones propias: lo único que anima es el pipeline de shaders, así
      # que el efecto va en un GLSL (ver ../dotfiles/ghostty/shaders/).
      # Se pueden encadenar más shaders añadiendo entradas a esta lista; la
      # salida de cada uno alimenta el iChannel0 del siguiente.
      custom-shader = [ "${../dotfiles/ghostty/shaders/cursor-smear.glsl}" ];
      # `true` = el bucle de animación corre solo en la ventana enfocada
      # (<10% de un core). Con `always` animaría también las de atrás, que en
      # una laptop es gastar batería en algo que no estás viendo.
      custom-shader-animation = true;

      # Ghostty se queda ctrl+tab y ctrl+shift+tab para SUS pestañas, y son los
      # mismos que herdr usa para cambiar de espacio (dotfiles/herdr/config.toml:
      # next_workspace / previous_workspace). Gana el terminal, así que dentro de
      # herdr el atajo no hacía nada.
      #
      # `unbind` los libera y el acorde le llega tal cual a la aplicación. Aquí
      # no se pierde nada: la multiplexación la hace herdr y las ventanas las
      # hace niri; las pestañas de Ghostty no se usan. Si algún día se quisieran,
      # siguen disponibles en ctrl+shift+flechas y en ctrl+av-pág/re-pág, que no
      # los toca nadie.
      keybind = [
        "ctrl+tab=unbind"
        "ctrl+shift+tab=unbind"
      ];

      # --------------------------------------------------------
      # Transparencia
      # --------------------------------------------------------
      # El blur NO se pone aquí: el `background-blur` de Ghostty depende del
      # protocolo de KWin y solo funciona en KDE Plasma, así que en niri no
      # haría nada. El desenfoque lo aplica el compositor con la window-rule de
      # dms/windowrules.kdl, que además usa el mismo dual-kawase que el resto
      # del escritorio.
      #
      # 0.9 y no más alto: con el fondo casi negro de Mocha (#1e1e2e), a 0.95
      # solo pasa un 5 % del wallpaper y el efecto desaparece salvo en zonas
      # muy claras — el coste del blur sin nada a cambio.
      background-opacity = 0.9;
      # `background-opacity-cells` se queda en false (el valor por defecto):
      # solo se transparenta el fondo de la ventana, no las celdas que traen su
      # propio color. En la práctica eso deja Neovim opaco, porque su tema pinta
      # un `Normal` explícito. Es intencionado: en Material 3 las superficies de
      # contenido son opacas y las que flotan son las que llevan blur. Si algún
      # día se quiere Neovim traslúcido, ponerlo en true también vuelve
      # traslúcidos la selección y la línea actual.

      gtk-single-instance = true;
      # Sin esto Ghostty se cierra entero al cerrar la última ventana: el
      # daemon muere, suelta el nombre de D-Bus y Mod+Return deja de hacer
      # nada hasta que abras una terminal por otro lado. Manteniéndolo vivo
      # (~165 MB en reposo) el atajo siempre responde en ~10-30 ms.
      quit-after-last-window-closed = false;
    };
  };

  # Ghostty en frío tarda ~900 ms en abrir ventana (GTK4 + libadwaita +
  # fontconfig + OpenGL: ~1300 .so y ~1100 archivos de fuentes por proceso)
  # contra ~120 ms de Alacritty. Ese costo no se puede bajar, solo se puede
  # pagar una sola vez: la unit que trae el paquete deja un proceso residente
  # (--gtk-single-instance=true --initial-window=false) y las ventanas se piden
  # por D-Bus con `gapplication launch` (ver el bind Mod+Return en binds.kdl),
  # que es un helper diminuto de glib. Así vuelve a ~120 ms.
  #
  # programs.ghostty.systemd.enable (default en Linux) escribe la unit y añade
  # dbus.packages —lo que habilita la activación por D-Bus—, pero no crea el
  # enlace de [Install]. Sin él el daemon solo arrancaría con la primera
  # ventana de la sesión, que pagaría el segundo completo.
  xdg.configFile."systemd/user/graphical-session.target.wants/app-com.mitchellh.ghostty.service".source =
    "${config.programs.ghostty.package}/share/systemd/user/app-com.mitchellh.ghostty.service";

  # Nota: las teclas muertas (´ + a = á) no funcionan en Ghostty sin
  # GTK_IM_MODULE=gtk-im-context-simple. La variable se declara a nivel de
  # escritorio en ../theme.nix, con el diagnóstico completo; aquí solo queda el
  # apunte porque este es el programa donde se notó.

  # DankMaterialShell deja un ~/.config/ghostty/config.ghostty vacío junto al
  # themes/dankcolors que sí genera. Ghostty lee los dos nombres de archivo y
  # se queja en cada arranque ("FileIsEmpty" + "both config files exist").
  # Se borra solo si está vacío: el día que DMS le escriba algo de verdad,
  # este guard no lo toca.
  home.activation.cleanEmptyGhosttyConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    stray="$HOME/.config/ghostty/config.ghostty"
    if test -f "$stray" && ! test -s "$stray"; then
      ${pkgs.coreutils}/bin/rm -f "$stray"
    fi
  '';

  # dbus-broker solo escanea los .service de activación al arrancar, y el bus
  # de sesión sobrevive a los re-logins: sin esto, el archivo que instala
  # dbus.packages no se ve hasta reiniciar la máquina y la activación falla con
  # "The name is not activatable". Es la red de seguridad para cuando el daemon
  # no esté corriendo; si el bus no existe (rebuild desde una TTY), no pasa nada.
  home.activation.reloadDbusServices = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if test -S "/run/user/$(${pkgs.coreutils}/bin/id -u)/bus"; then
      DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(${pkgs.coreutils}/bin/id -u)/bus" \
        ${pkgs.dbus}/bin/dbus-send --session --dest=org.freedesktop.DBus \
          /org/freedesktop/DBus org.freedesktop.DBus.ReloadConfig || true
    fi
  '';
}
