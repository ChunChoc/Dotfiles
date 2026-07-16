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

  # T480 Synaptics touchpads can fail IRQ setup on the RMI/SMBus path.
  boot.kernelParams = [ "psmouse.synaptics_intertouch=0" ];

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
  # resume_offset: posición física del swapfile dentro del btrfs. Se obtiene
  # con `btrfs inspect-internal map-swapfile -r /var/lib/swapfile` DESPUÉS
  # de que el primer rebuild cree el archivo, y se fija aquí (fase 2).
  # boot.kernelParams = [ "resume_offset=PENDIENTE" ];

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
