{ ... }:
{
  # Permitir paquetes con licencia unfree.
  nixpkgs.config.allowUnfree = true;

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

  # DNS cifrado local (DNSCrypt/DoH) vía dnscrypt-proxy2
  # Las apps consultan a 127.0.0.1, dnscrypt cifra y reenvía por 443.
  networking.networkmanager.dns = "none";
  networking.nameservers = [ "127.0.0.1" "::1" ];

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:53" "[::1]:53" ];

      # Resolvers DNSCrypt con filtrado de malware (Quad9).
      # Anonymized DNS SOLO funciona con DNSCrypt, no con DoH.
      server_names = [
        "quad9-dnscrypt-ip4-filter-pri"
        "quad9-dnscrypt-ip4-filter-alt"
      ];

      require_dnssec = false;   # subir a true tras verificar
      require_nolog = true;
      require_nofilter = false; # permitir servidores que filtran

      ipv6_servers = false;
      dnscrypt_servers = true;
      doh_servers = false;      # desactivado: incompatible con relays

      # Cache local de respuestas
      cache = true;

      # Bootstrap resiliente para arrancar las listas
      # incluso en redes que rompen el puerto 53.
      bootstrap_resolvers = [ "9.9.9.9:53" "1.1.1.1:53" ];
      ignore_system_dns = true;

      # --- Anonymized DNS: el relay oculta tu IP al resolver ---
      # Cada consulta sale por un relay (operadores distintos a Quad9).
      # Verifica nombres válidos con:  dnscrypt-proxy -list-all-relays
      anonymized_dns = {
        routes = [
          {
            server_name = "*";
            via = [ "anon-cs-fr" "anon-cs-nl" ];
          }
        ];
        skip_incompatible = true;
      };

      # Fuentes de listas firmadas (resolvers + relays)
      sources = {
        public-resolvers = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
            "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          ];
          cache_file = "/var/cache/dnscrypt-proxy/public-resolvers.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
        relays = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md"
            "https://download.dnscrypt.info/resolvers-list/v3/relays.md"
          ];
          cache_file = "/var/cache/dnscrypt-proxy/relays.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
      };
    };
  };

  # Gestor de autorización a nivel de sistema (Para run0)
  security.polkit.enable = true;
}
