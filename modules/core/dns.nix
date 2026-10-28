{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Marca que deja `dns-emergencia` para que el dispatcher no vuelva a
  # levantar dnscrypt-proxy a espaldas de uno al cambiar de red. Vive en /run
  # para que un reinicio vuelva siempre al modo normal.
  marcaEmergencia = "/run/dns-emergencia";

  # El resolv.conf "normal" sale de `networking.nameservers` (lo mismo que
  # escribe resolvconf), así `dns-normal` no repite las IPs a mano.
  resolvConfNormal =
    lib.concatMapStrings (ns: "nameserver ${ns}\n") config.networking.nameservers + "options edns0\n";
  escribirResolvNormal = "printf '%s' ${lib.escapeShellArg resolvConfNormal} > /etc/resolv.conf";

  # Ambos comandos tocan /etc/resolv.conf y systemd: si no se corren como root
  # se relanzan solos con sudo, para no tener que acordarse en plena emergencia.
  comoRoot = ''
    if [ "$(id -u)" -ne 0 ]; then
      exec /run/wrappers/bin/sudo "$0" "$@"
    fi
    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.gawk
        pkgs.iproute2
        pkgs.systemd
      ]
    }:$PATH
  '';

  # Plan B cuando dnscrypt no consigue hablar con nadie. Se usa primero el
  # gateway porque en el hotspot del teléfono es lo único que seguro responde:
  # varias operadoras móviles bloquean el UDP 53 hacia afuera (comprobado: 9.9.9.9
  # y 1.1.1.1 no responden por UDP, sí por TCP, y el gateway sí), por eso apuntar
  # directo a 9.9.9.9 no funcionó ahí. Quad9 queda de segunda para otras redes.
  # Se pregunta la ruta hacia 9.9.9.9 en vez de leer `default` porque con dos
  # interfaces arriba (WiFi + cable) da el gateway que de verdad se usa.
  dnsEmergencia = pkgs.writeShellScriptBin "dns-emergencia" ''
    set -eu
    ${comoRoot}
    gw=$(ip -4 route get 9.9.9.9 2>/dev/null \
      | awk '{ for (i = 1; i < NF; i++) if ($i == "via") { print $(i + 1); exit } }')

    systemctl stop dnscrypt-proxy.service
    touch ${marcaEmergencia}
    {
      if [ -n "$gw" ]; then echo "nameserver $gw"; fi
      echo "nameserver 9.9.9.9"
      echo "options edns0"
    } > /etc/resolv.conf

    echo "DNS de emergencia (sin cifrar): ''${gw:-sin gateway} y 9.9.9.9"
    echo "Para volver a DNSCrypt: dns-normal"
  '';

  dnsNormal = pkgs.writeShellScriptBin "dns-normal" ''
    set -eu
    ${comoRoot}
    rm -f ${marcaEmergencia}
    ${escribirResolvNormal}
    systemctl restart dnscrypt-proxy.service
    echo "DNS normal: 127.0.0.1 -> dnscrypt-proxy (reiniciado)"
  '';

  # Relays de anonymized DNS. Antes eran 5 en Europa y uno (`anon-inconnu`) ya
  # no existe en la lista: cada consulta cruzaba el Atlántico dos veces y con la
  # latencia del hotspot llegaba a los TIMEOUT que se ven en el journal. Ahora
  # van primero relays en EE. UU. (más cerca de Guatemala) y se dejan dos
  # europeos como respaldo, de 4 operadores distintos.
  relaysCryptostorm = [
    "anon-cs-fl" # CryptoStorm, Miami
    "anon-cs-tx" # CryptoStorm, Dallas
  ];
  relaysDnscrypt = [
    "dnscry.pt-anon-atlanta-ipv4" # dnscry.pt, Atlanta
    "dnscry.pt-anon-houston-ipv4" # dnscry.pt, Houston
  ];
  relaysEuropa = [
    "anon-scaleway2" # Frank Denis (autor de dnscrypt), Francia
    "anon-serbica" # litepay.ch, Países Bajos
  ];
in
{
  # DNS cifrado local (DNSCrypt) vía dnscrypt-proxy2
  # Las apps consultan a 127.0.0.1, dnscrypt cifra y reenvía.
  networking.networkmanager.dns = "none";
  networking.nameservers = [
    "127.0.0.1"
    "::1"
  ];

  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = [
        "127.0.0.1:53"
        "[::1]:53"
      ];

      # Antes: 4 servidores Quad9, pero `-alt` y `-ecs-alt` desaparecieron de
      # la lista pública y dnscrypt-proxy los ignora sin avisar. En la práctica
      # eran 2 servidores del mismo operador: si Quad9 o su ruta fallaban en una
      # red, no quedaba nada. Ahora son 7 de 4 operadores, todos DNSCrypt sobre
      # IPv4, no-log, con DNSSEC y compatibles con anonimización (CleanBrowsing
      # se descartó por no aceptarla). Se eligieron en América por latencia.
      #
      # Ojo: solo Quad9 bloquea dominios maliciosos; los demás no filtran. Con
      # varios operadores ese bloqueo pasa a ser "a veces"; es el precio de no
      # depender de uno solo (no hay otro resolver de solo-malware que acepte
      # relays).
      server_names = [
        "quad9-dnscrypt-ip4-filter-pri" # Quad9 (anycast)
        "quad9-dnscrypt-ip4-filter-ecs-pri" # Quad9 con ECS (anycast)
        "plan9dns-mx" # plan9-dns, Ciudad de México
        "plan9dns-fl" # plan9-dns, Miami
        "dnscry.pt-miami-ipv4" # dnscry.pt, Miami
        "dnscry.pt-dallas-ipv4" # dnscry.pt, Dallas
        "dnscrypt.ca-ipv4" # dnscrypt.ca, Canadá
      ];

      require_dnssec = true; # solo resolvers que validan DNSSEC
      require_nolog = true;
      require_nofilter = false; # permitir servidores que filtran (Quad9)

      # Evita fugas de nombres locales/inventados a internet:
      block_unqualified = true; # nombres de una sola etiqueta (p.ej. "foo")
      block_undelegated = true; # TLDs no delegados (.lan, .home, .internal)

      ipv6_servers = false;
      dnscrypt_servers = true;
      doh_servers = false; # desactivado: incompatible con relays

      # Balanceo: probar varios servidores, no casarse con uno.
      lb_strategy = "p2";
      lb_estimator = true;

      # Cache local de respuestas
      cache = true;

      # netprobe corre *antes* de abrir el puerto 53: mientras espera red,
      # ninguna consulta responde. Con 60 s el arranque sin red quedaba un
      # minuto entero sin DNS (se ve en el journal). Ahora el dispatcher de
      # abajo reinicia el servicio cuando la red sube, así que basta con
      # esperar poco y arrancar.
      netprobe_timeout = 10;
      netprobe_address = "9.9.9.9:53";

      # Bootstrap resiliente para arrancar las listas
      # incluso en redes que rompen el puerto 53.
      bootstrap_resolvers = [
        "9.9.9.9:53"
        "1.1.1.1:53"
      ];
      ignore_system_dns = true;

      # --- Anonymized DNS: el relay oculta tu IP al resolver ---
      # El anonimato depende de que relay y servidor sean de operadores
      # distintos (si son el mismo, ve tu IP *y* tu consulta). dnscrypt-proxy
      # busca primero la ruta con el nombre exacto del servidor y solo después
      # `*`, así que los servidores de dnscry.pt tienen su propia ruta que
      # excluye los relays de dnscry.pt.
      anonymized_dns = {
        routes = [
          {
            server_name = "dnscry.pt-miami-ipv4";
            via = relaysCryptostorm ++ relaysEuropa;
          }
          {
            server_name = "dnscry.pt-dallas-ipv4";
            via = relaysCryptostorm ++ relaysEuropa;
          }
          {
            server_name = "*";
            via = relaysCryptostorm ++ relaysDnscrypt ++ relaysEuropa;
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
            "https://cdn.jsdelivr.net/gh/DNSCrypt/dnscrypt-resolvers@master/v3/public-resolvers.md"
          ];
          cache_file = "/var/cache/dnscrypt-proxy/public-resolvers.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
        relays = {
          urls = [
            "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md"
            "https://download.dnscrypt.info/resolvers-list/v3/relays.md"
            "https://cdn.jsdelivr.net/gh/DNSCrypt/dnscrypt-resolvers@master/v3/relays.md"
          ];
          cache_file = "/var/cache/dnscrypt-proxy/relays.md";
          minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        };
      };
    };
  };

  # Reiniciar dnscrypt-proxy al cambiar de red. Aunque detecta el cambio y rota
  # su clave, los servidores que marcó como caídos en la red anterior siguen
  # así un rato; reiniciar fuerza a volver a medirlos todos desde la red nueva.
  # `up` cubre conectarse a otra red; `connectivity-change` cubre la misma red
  # que pasa de "sin internet" a tenerlo (típico del hotspot recién encendido).
  networking.networkmanager.dispatcherScripts = [
    {
      type = "basic";
      source = pkgs.writeShellScript "dnscrypt-reiniciar-al-cambiar-red" ''
        export PATH=${
          lib.makeBinPath [
            pkgs.coreutils
            pkgs.gawk
            pkgs.systemd
          ]
        }
        iface="$1"
        accion="$2"

        case "$accion" in
          up)
            # Interfaces virtuales (VM, contenedores) no cambian la salida a internet.
            case "$iface" in lo | virbr* | vnet* | veth* | docker* | br-*) exit 0 ;; esac
            ;;
          connectivity-change)
            case "''${CONNECTIVITY_STATE:-}" in FULL | LIMITED | PORTAL) ;; *) exit 0 ;; esac
            ;;
          *) exit 0 ;;
        esac

        # En modo emergencia no se toca dnscrypt: solo se actualiza el gateway,
        # que cambia con la red.
        if [ -e ${marcaEmergencia} ]; then
          exec ${dnsEmergencia}/bin/dns-emergencia
        fi

        # Fuera del modo emergencia, resolv.conf tiene que apuntar a dnscrypt.
        # Si quedó editado a mano (p. ej. `nameserver 9.9.9.9`) dnscrypt puede
        # estar sano y aun así nadie le pregunta: pasó el 2026-10-28, cuando un
        # 9.9.9.9 viejo sobrevivió al switch y en hotspots que bloquean el UDP 53
        # hacia afuera no había DNS. Reescribirlo en cada cambio de red lo corrige
        # solo, y como /run se vacía al apagar, también vuelve al modo normal
        # tras reiniciar en modo emergencia.
        ${escribirResolvNormal}

        # `up` y `connectivity-change` suelen llegar juntos; si el servicio
        # arrancó hace menos de 5 s, el segundo reinicio solo cortaría el sondeo
        # del primero.
        inicio=$(systemctl show -P ActiveEnterTimestampMonotonic dnscrypt-proxy.service)
        ahora=$(awk '{ printf "%d", $1 * 1000000 }' /proc/uptime)
        if [ "''${inicio:-0}" -gt 0 ] && [ $((ahora - inicio)) -lt 5000000 ]; then
          exit 0
        fi

        systemctl restart --no-block dnscrypt-proxy.service
      '';
    }
  ];

  environment.systemPackages = [
    dnsEmergencia
    dnsNormal
  ];
}
