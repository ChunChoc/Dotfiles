{ pkgs, ... }:
{
  # Zona horaria y Locale
  time.timeZone = "America/Guatemala";
  i18n.defaultLocale = "en_US.UTF-8";
  
  # Teclado latino en TTY
  console = {
     keyMap = "la-latin1";
  };
  
  # Teclado latino en el sistema
  services.xserver.xkb = {
    layout = "latam";
    variant = "";
  };

  # Habilitar Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Limpieza automática de basura
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 3d";
  };
}