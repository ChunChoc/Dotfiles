{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.myFeatures.printing {
    # Impresión. También registra cups-pk-helper en D-Bus/Polkit para DMS.
    services.printing = {
      enable = true;

      # La G2170 es el nombre comercial en LATAM; por USB se identifica a sí
      # misma como "G2070 series", que sí tiene PPD oficial en cnijfilter2.
      # Gutenprint queda como red de seguridad (familia PIXMA G2000) por si
      # alguna vez hay que cambiar de driver.
      drivers = [ pkgs.cnijfilter2 pkgs.gutenprint ];

      # Por defecto CUPS pausa la cola al primer error y no la reactiva solo:
      # esa es la causa típica del "imprimió una vez y nunca más".
      extraConf = ''
        ErrorPolicy retry-job
      '';

      # Demonio siempre arriba en lugar de activación por socket; evita
      # carreras al enchufar/desenchufar el cable USB.
      startWhenNeeded = false;
    };

    # La cola se declara aquí, no con `lpadmin` a mano: así cada
    # `nixos-rebuild switch` la reconstruye idéntica y no puede quedarse rota
    # para siempre en el estado mutable de /var/lib/cups.
    hardware.printers = {
      ensureDefaultPrinter = "Canon_G2170";
      ensurePrinters = [{
        name = "Canon_G2170";
        description = "Canon PIXMA G2170 (USB)";
        location = "Escritorio";
        # Sale de `lpinfo -v`. El serial es del equipo físico: si se cambia la
        # impresora hay que volver a leerlo.
        deviceUri = "usb://Canon/G2070%20series?serial=602FDA&interface=1";
        model = "canong2070.ppd";
        # El PPD viene con A4 por defecto; aquí se usa Letter.
        ppdOptions.PageSize = "Letter";
      }];
    };

    # Necesario para hablar con el backend USB de CUPS.
    users.users.chunchoc.extraGroups = [ "lp" ];
  };
}
