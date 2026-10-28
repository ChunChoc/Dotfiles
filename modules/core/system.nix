{ lib, ... }:
{
  # Permitir paquetes con licencia unfree.
  nixpkgs.config.allowUnfree = true;

  # Red base común a todos los hosts (los hosts solo declaran quirks).
  # Las conexiones se configuran interactivamente con nmcli o nmtui.
  networking.networkmanager.enable = lib.mkDefault true;
  # MAC WiFi aleatoria por conexión: evita rastreo entre redes.
  networking.networkmanager.wifi.macAddress = lib.mkDefault "random";
  # Firewall base; los features abren solo sus puertos.
  networking.firewall.enable = lib.mkDefault true;

  # Versión de estado inicial de la instalación (un host nuevo instalado
  # con otra release debe sobreescribirla en su default.nix).
  system.stateVersion = lib.mkDefault "25.11";

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
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Limpieza automática de basura
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  # Desduplicador automático
  nix.settings.auto-optimise-store = true;

  # Gestor de autorización a nivel de sistema (Para run0)
  security.polkit.enable = true;
}
