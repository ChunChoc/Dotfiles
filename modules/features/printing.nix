{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.myFeatures.printing {
    # Impresión. También registra cups-pk-helper en D-Bus/Polkit para DMS.
    services.printing = {
      enable = true;

      # La Canon PIXMA G2170 no tiene un PPD con su nombre exacto en ningún
      # driver libre ni en el oficial de Canon. Se instalan los dos juegos de
      # PPD de su misma familia MegaTank y se usa el que imprima bien:
      #   - gutenprint  -> familia "PIXMA G2000" (todas apuntan al mismo modelo)
      #   - cnijfilter2 -> PPDs G2020/G2030/G2060/G2070 (driver oficial Canon)
      drivers = [ pkgs.gutenprint pkgs.cnijfilter2 ];

      # Por defecto CUPS pausa la cola al primer error y no la reactiva solo:
      # esa es la causa típica del "imprimió una vez y nunca más".
      extraConf = ''
        ErrorPolicy retry-job
      '';

      # Demonio siempre arriba en lugar de activación por socket; evita
      # carreras al enchufar/desenchufar el cable USB.
      startWhenNeeded = false;
    };

    # Necesario para hablar con el backend USB de CUPS.
    users.users.chunchoc.extraGroups = [ "lp" ];
  };
}
