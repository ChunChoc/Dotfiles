{ pkgs, ... }:

{
  # Dar prioridad por usuario al proveedor FileManager1 de Dux.
  # El MIME de carpetas no decide este D-Bus, que usan otras aplicaciones
  # para "mostrar en carpeta".
  xdg.dataFile."dbus-1/services/org.freedesktop.FileManager1.service".source =
    "${pkgs.dux-files}/share/dbus-1/services/dev.duxlabs.files.FileManager1.service";

  # Programas por defecto
  xdg.mimeApps = {
    enable = true;
    # Conservar la asociación de FLAC que ya existía en el archivo editable.
    associations.added."audio/flac" = [ "rmpc.desktop" ];
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

      # Comprimidos -> Dux Files, que los extrae sin un gestor adicional.
      "application/zip" = [ "dev.duxlabs.files.desktop" ];
      "application/x-tar" = [ "dev.duxlabs.files.desktop" ];
      "application/gzip" = [ "dev.duxlabs.files.desktop" ];
      "application/x-compressed-tar" = [ "dev.duxlabs.files.desktop" ];
      "application/x-bzip2" = [ "dev.duxlabs.files.desktop" ];
      "application/x-bzip2-compressed-tar" = [ "dev.duxlabs.files.desktop" ];
      "application/x-xz" = [ "dev.duxlabs.files.desktop" ];
      "application/x-xz-compressed-tar" = [ "dev.duxlabs.files.desktop" ];
      "application/zstd" = [ "dev.duxlabs.files.desktop" ];
      "application/x-zstd-compressed-tar" = [ "dev.duxlabs.files.desktop" ];
      "application/x-lzma" = [ "dev.duxlabs.files.desktop" ];
      "application/x-lzma-compressed-tar" = [ "dev.duxlabs.files.desktop" ];
      "application/x-7z-compressed" = [ "dev.duxlabs.files.desktop" ];
      "application/vnd.rar" = [ "dev.duxlabs.files.desktop" ];
      "application/x-cpio" = [ "dev.duxlabs.files.desktop" ];
    };
  };
}
