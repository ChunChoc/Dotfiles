{ pkgs, lib, osConfig, ... }:

{
  # Parte de usuario del feature virtualization (el sistema se configura en
  # modules/features/virtualization.nix; aquí solo va lo que pertenece al
  # perfil de chunchoc).
  config = lib.mkIf osConfig.myFeatures.virtualization {
    home.packages = with pkgs; [
      virt-viewer # visor SPICE/VNC independiente de virt-manager
    ];

    # Que virt-manager abra directamente la conexión del sistema en vez de
    # pedirla en cada arranque.
    dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        uris = [ "qemu:///system" ];
        autoconnect = [ "qemu:///system" ];
      };

      # Por defecto SPICE, que es lo que soporta win-spice y la redirección USB.
      "org/virt-manager/virt-manager/new-vm" = {
        graphics-type = "spice";
      };
    };
  };
}
