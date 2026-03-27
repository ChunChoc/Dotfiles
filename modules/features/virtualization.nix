{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.myFeatures.virtualization {
    # Virtualización (KVM/QEMU)
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true; # Para emular TPM (Windows 11)
      };
    };

    # Instala Virt-Manager
    programs.virt-manager.enable = true;

    # Agregar usuario al grupo libvirtd
    users.users.chunchoc.extraGroups = [ "libvirtd" ];
  };
}
