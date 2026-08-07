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
