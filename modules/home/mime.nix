{ pkgs, ... }:

{
  # Dar prioridad por usuario al proveedor FileManager1 de Dux, sin quitar
  # Nautilus del portal GNOME. El MIME de carpetas no decide este D-Bus:
  # sin esto, "mostrar en carpeta" podría seguir activando Nautilus.
  xdg.dataFile."dbus-1/services/org.freedesktop.FileManager1.service".source =
    "${pkgs.dux-files}/share/dbus-1/services/dev.duxlabs.files.FileManager1.service";

  # Programas por defecto
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Documentos -> zathura
      "application/pdf" = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];

      # Imágenes -> imv
      "image/jpeg" = [ "imv.desktop" ];
      "image/png" = [ "imv.desktop" ];
      "image/gif" = [ "imv.desktop" ];
      "image/webp" = [ "imv.desktop" ];

      # Videos -> mpv
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ]; # Archivos .mkv
      "video/webm" = [ "mpv.desktop" ];

      # Carpetas -> Dux Files. El selector abrir/guardar se elige por separado
      # mediante xdg.portal.config.niri en modules/desktop.nix.
      "inode/directory" = [ "dev.duxlabs.files.desktop" ];
    };
  };
}
