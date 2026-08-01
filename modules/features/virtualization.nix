{ config, lib, pkgs, ... }:

let
  # pkgs.virtio-win y pkgs.win-spice son la ISO ya extraída (vuelcan sus
  # carpetas en la raíz del paquete), así que no sirven en systemPackages.
  # La reempaquetamos como ISO para poder montarla como CD-ROM en la VM.
  virtioWinIso = pkgs.runCommand "virtio-win.iso"
    { nativeBuildInputs = [ pkgs.cdrkit ]; }
    ''
      genisoimage -J -r -V virtio-win -graft-points -o $out \
        virtio-win/=${pkgs.virtio-win} \
        spice-guest-tools/=${pkgs.win-spice}
    '';
in

{
  config = lib.mkIf config.myFeatures.virtualization {
    # --------------------------------------------------------
    # Virtualización de sistema (KVM/QEMU + libvirt)
    # La parte de usuario (virt-manager, dconf, virt-viewer) vive en
    # modules/home/virtualization.nix leyendo este mismo flag vía osConfig.
    # --------------------------------------------------------
    virtualisation.libvirtd = {
      enable = true;

      # En un portátil no queremos que las VMs arranquen solas al bootear,
      # pero sí que se apaguen limpiamente al apagar el equipo.
      onBoot = "ignore";
      onShutdown = "shutdown";

      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;

        # Nota: ya no se configura `qemu.ovmf`; nixpkgs eliminó ese submódulo
        # porque las imágenes OVMF (UEFI, incluidas las variantes con Secure
        # Boot que pide Windows 11) vienen por defecto con QEMU.

        # swtpm emula el TPM 2.0 que exige el instalador de Windows 11.
        swtpm.enable = true;

        # virtiofsd permite compartir carpetas del host con la VM sin red
        # (útil para pasar archivos del curso al invitado Windows).
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
    };

    # virt-manager como GUI (también habilita programs.dconf, del que dependen
    # sus ajustes de usuario en modules/home/virtualization.nix).
    programs.virt-manager.enable = true;

    # Redirección de USB del host al invitado desde virt-manager (SPICE).
    virtualisation.spiceUSBRedirection.enable = true;

    # La red NAT por defecto de libvirt (virbr0) necesita DHCP/DNS hacia el
    # host; sin esto el firewall puede dejar al invitado sin conexión.
    networking.firewall.trustedInterfaces = [ "virbr0" ];

    environment.systemPackages = [ pkgs.virtiofsd ];

    # Directorio de imágenes del pool por defecto de libvirt, con la ISO de
    # drivers enlazada ahí para tenerla a mano en virt-manager. Se monta como
    # segundo CD-ROM al instalar Windows (sin ella no detecta el disco virtio)
    # y trae también el agente SPICE (portapapeles y resolución dinámica).
    systemd.tmpfiles.rules = [
      "d /var/lib/libvirt/images 0711 root root -"
      "L+ /var/lib/libvirt/images/virtio-win.iso - - - - ${virtioWinIso}"
    ];

    # Acceso a libvirt y a /dev/kvm sin sudo.
    users.users.chunchoc.extraGroups = [ "libvirtd" "kvm" ];
  };
}
