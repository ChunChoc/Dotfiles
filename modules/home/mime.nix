{ ... }:

{
  # Programas por defecto
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Imágenes -> imv
      "image/jpeg" = [ "imv.desktop" ];
      "image/png"  = [ "imv.desktop" ];
      "image/gif"  = [ "imv.desktop" ];
      "image/webp" = [ "imv.desktop" ];

      # Videos -> mpv
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ]; # Archivos .mkv
      "video/webm" = [ "mpv.desktop" ];
    };
  };
}
