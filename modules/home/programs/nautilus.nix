{ pkgs, ... }:

{
  # --------------------------------------------------------
  # Nautilus — gestor de archivos
  # --------------------------------------------------------
  # El módulo de niri ya mete Nautilus en el closure por su cuenta
  # (programs.niri.useNautilus, activo por defecto: se lo pasa a
  # services.dbus.packages porque el FileChooser del portal de GNOME lo
  # necesita). Pero eso solo lo hace activable por D-Bus —de ahí sale el
  # "mostrar en carpeta" de los navegadores—, no instala el .desktop ni lo pone
  # en el PATH. Por eso hace falta declararlo aquí para poder abrirlo a mano.
  home.packages = [ pkgs.nautilus ];

  # Arranque en caliente, el mismo truco que Ghostty (ver programs/ghostty.nix).
  #
  # Nautilus en frío tarda ~2 s en abrir ventana: es GTK4 + libadwaita y carga
  # ~1300 .so repartidos en ~100 rutas de /nix/store, más gstreamer, alsa y
  # tinysparql. Ese costo no se puede bajar, solo pagarse una vez: este servicio
  # deja el proceso residente (~150 MB) y el bind Mod+E pide la ventana por
  # D-Bus con `gapplication launch`, que es un helper diminuto de glib.
  #
  # Hubo un intento anterior que no funcionó, y el fallo estaba en el bind, no
  # aquí: había un `spawn-at-startup "nautilus" --gapplication-service` en
  # niri/config.kdl, pero Mod+E lanzaba `nautilus` a secas. Eso arranca un
  # proceso completo y solo al final descubre por D-Bus que ya había otra
  # instancia, así que se pagaban los 2 s igual Y los 150 MB. Las dos mitades
  # tienen que ir juntas: el servicio de abajo y el `gapplication launch` del
  # bind (modules/home/dotfiles/niri/dms/binds.kdl).
  #
  # Va como unit de systemd y no como spawn-at-startup de niri porque el paquete
  # no trae ninguna (a diferencia de Ghostty) y porque así systemd lo ordena
  # dentro de la sesión gráfica y lo reinicia si se cae.
  systemd.user.services."app-org.gnome.Nautilus" = {
    Unit = {
      Description = "Nautilus, residente para que Mod+E abra al instante";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      # `Type = "dbus"` con BusName hace que systemd espere a que el nombre esté
      # tomado antes de dar la unit por arrancada. Con "simple" el nombre se
      # registra después y un Mod+E muy temprano encontraría el bus vacío y
      # arrancaría un segundo proceso.
      Type = "dbus";
      BusName = "org.gnome.Nautilus";
      ExecStart = "${pkgs.nautilus}/bin/nautilus --gapplication-service";
      # "on-failure" y no "always": si algún día sale limpio por su cuenta
      # (inactividad, un cierre pedido a mano), que no entre en bucle.
      Restart = "on-failure";
      RestartSec = 3;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
