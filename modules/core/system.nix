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
    options = "--delete-older-than 7d";
  };
  # Desduplicador automático
  nix.settings.auto-optimise-store = true;

  # DNS de Cloudflare y AdGuard (Public Default)
  networking.nameservers = [ "1.1.1.1" "94.140.14.14" ];

  # Gestor de autorización a nivel de sistema (Para run0)
  security.polkit.enable = true;
}