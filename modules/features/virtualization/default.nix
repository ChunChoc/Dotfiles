{ config, lib, pkgs, ... }:

let
  spiceVdagentMsi = pkgs.fetchurl {
    url = "https://www.spice-space.org/download/windows/vdagent/vdagent-win-0.10.0/spice-vdagent-x64-0.10.0.msi";
    hash = "sha256-d2KUNXBbwn3X0lJenSCE9y26tf2/MQ6BL5EzL+GNAOs=";
  };

  # virtiofs.exe (el servicio VirtioFsSvc del invitado) depende de WinFsp, que
  # NO viene en virtio-win-guest-tools.exe: se distribuye aparte por licencia.
  # Sin él VirtioFsSvc no arranca y la carpeta compartida nunca aparece.
  winfspMsi = pkgs.fetchurl {
    url = "https://github.com/winfsp/winfsp/releases/download/v2.1/winfsp-2.1.25156.msi";
    hash = "sha256-Bzpw4A93Qj40vtmLhuYA3vkzk7pYIiBPrFeikyTbn3o=";
  };

  # Reempaqueta los controladores VirtIO y QEMU Guest Agent con los MSI de
  # SPICE vdagent y WinFsp para poder montarlos como CD-ROM en la VM.
  virtioWinIso = pkgs.runCommand "virtio-win.iso"
    { nativeBuildInputs = [ pkgs.cdrkit pkgs.libfaketime ]; }
    ''
      faketime "2000-01-01 00:00:00" genisoimage -J -r -V virtio-win -graft-points -o $out \
        virtio-win/=${pkgs.virtio-win} \
        spice-vdagent-x64-0.10.0.msi=${spiceVdagentMsi} \
        winfsp.msi=${winfspMsi}
    '';

  # Empaquetar el script como writeShellApplication (en vez de dejarlo suelto en
  # el repo) hace que sus dependencias lleguen por runtimeInputs. NixOS no trae
  # chattr/lsattr en el PATH por defecto, y un script suelto falla a mitad por
  # eso; aquí es imposible. Además shellcheck corre en tiempo de build.
  vmNocow = pkgs.writeShellApplication {
    name = "vm-nocow";
    runtimeInputs = with pkgs; [ e2fsprogs libvirt qemu-utils coreutils gnugrep gawk ];
    text = builtins.readFile ./vm-nocow.sh;
  };
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

    # e2fsprogs trae chattr/lsattr, necesarios para inspeccionar el nodatacow de
    # las imágenes en btrfs. vmNocow es el comando `vm-nocow` (ver README.md).
    environment.systemPackages = [ pkgs.virtiofsd pkgs.e2fsprogs vmNocow ];

    # Directorio de imágenes del pool por defecto de libvirt, con la ISO de
    # VirtIO/QEMU Guest Agent enlazada ahí para tenerla a mano en virt-manager.
    # Se monta como segundo CD-ROM al instalar Windows (sin ella no detecta el
    # disco virtio).
    #
    # OJO: instalar solo los drivers desde el Administrador de dispositivos NO
    # basta. Hay que ejecutar virtio-win/virtio-win-guest-tools.exe dentro del
    # invitado, que es lo que instala el agente SPICE (servicio `vdservice`);
    # sin él no hay resolución dinámica, ni portapapeles, ni arrastrar-soltar.
    # Como respaldo, spice-vdagent-x64-0.10.0.msi está en la raíz de la ISO.
    systemd.tmpfiles.rules = [
      "d /var/lib/libvirt/images 0711 root root -"
      "L+ /var/lib/libvirt/images/virtio-win.iso - - - - ${virtioWinIso}"
    ];

    # La raíz es btrfs, que ya hace copy-on-write; un qcow2 encima es CoW sobre
    # CoW, y la imagen se fragmenta hasta arrastrarse. `chattr +C` sobre el
    # directorio hace que los archivos creados dentro nazcan con nodatacow.
    # No afecta a los que ya existen: esos hay que recrearlos (docs/vm-nocow.sh).
    systemd.services.libvirt-images-nocow = {
      description = "Marcar /var/lib/libvirt/images como nodatacow (btrfs)";
      wantedBy = [ "multi-user.target" ];
      before = [ "libvirtd.service" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      # En un sistema de archivos sin nodatacow chattr falla; no es motivo para
      # dejar el arranque en rojo.
      script = ''
        ${pkgs.e2fsprogs}/bin/chattr +C /var/lib/libvirt/images || true
      '';
    };

    # Acceso a libvirt y a /dev/kvm sin sudo.
    users.users.chunchoc.extraGroups = [ "libvirtd" "kvm" ];
  };
}
