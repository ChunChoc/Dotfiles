{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # --- ACTIVAR FEATURES ---
  myFeatures = {
    development = true;
    communication = true;
    office = true;
    virtualization = false;
    localsend = true;
    gaming = false;
    batteryChargeLimit = 90;
  };

  # Nombre del hostname
  networking.hostName = "thinkpad";

  boot.kernelParams = [
    # T480 Synaptics touchpads can fail IRQ setup on the RMI/SMBus path.
    "psmouse.synaptics_intertouch=0"
    # Posición física del swapfile dentro del btrfs para resumir de
    # hibernación; ver el bloque de hibernación más abajo.
    "resume_offset=17835264"
  ];

  # --- Hibernación con swapfile cifrado ---
  # El swapfile vive dentro del btrfs sobre LUKS (cryptroot), así que la
  # imagen de hibernación queda cifrada en reposo y resumir pide la
  # contraseña de LUKS. Tamaño ≈ RAM (16 GiB); al ampliar a 32 GB de RAM
  # hay que subirlo y recalcular resume_offset.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024; # MiB
    }
  ];

  # Partición (desbloqueada) donde está el swapfile con la imagen de resume.
  boot.resumeDevice = "/dev/mapper/cryptroot";
  # El resume_offset (en boot.kernelParams, arriba) se obtiene con
  # `btrfs inspect-internal map-swapfile -r /var/lib/swapfile`.
  # OJO: si el swapfile se recrea (p. ej. al agrandarlo), hay que volver a
  # calcularlo y actualizar ese valor.

  # suspend-then-hibernate: tras 1 h suspendida, hiberna sola (RAM al
  # swapfile cifrado y apagado total; las llaves salen de la RAM).
  systemd.sleep.settings.Sleep.HibernateDelaySec = "60min";

  # Enable BlueZ for the built-in Bluetooth adapter.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # Use the desktop-provided SSH agent for this host.
  services.gnome.gcr-ssh-agent.enable = true;
}
