{ pkgs, lib, osConfig, ... }:

{
  # App + lanzador de LocalSend, controlados por el mismo flag que abre
  # sus puertos en modules/features/localsend.nix.
  config = lib.mkIf osConfig.myFeatures.localsend {
    home.packages = [ pkgs.localsend ];

    xdg.dataFile."applications/LocalSend.desktop".text = ''
      [Desktop Entry]
      Categories=GTK;FileTransfer;Utility
      Exec=env GTK_CSD=0 localsend_app %U
      GenericName=An open source cross-platform alternative to AirDrop
      Icon=localsend
      Keywords=Sharing;LAN;Files
      Name=LocalSend
      StartupNotify=true
      StartupWMClass=localsend_app
      Terminal=false
      Type=Application
      Version=1.5
    '';
  };
}
