{ ... }:

{
  # Programas por defecto
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Documentos -> zathura
      "application/pdf" = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];

      # Imágenes -> imv
      "image/jpeg" = [ "imv.desktop" ];
      "image/png"  = [ "imv.desktop" ];
      "image/gif"  = [ "imv.desktop" ];
      "image/webp" = [ "imv.desktop" ];

      # Videos -> mpv
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ]; # Archivos .mkv
      "video/webm" = [ "mpv.desktop" ];

      # Carpetas -> Nautilus. Es lo que se abre desde "mostrar en carpeta" de
      # otras apps.
      #
      # Declararlo es redundante hoy (Nautilus ya es el único candidato), pero
      # se deja explícito para que el handler no dependa del orden en que
      # aparezcan los .desktop si algún día se instala otro gestor.
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    };
  };
}
