{ pkgs, ... }:
{
  # Niri y DMS
  programs.niri.enable = true;
  programs.dms-shell.enable = true;

  # SDDM con Catppuccin
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "catppuccin-mocha-mauve";
  };

  # Audio (Pipewire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Impresión. También registra cups-pk-helper en D-Bus/Polkit para DMS.
  services.printing.enable = true;

  # Estado de batería para DMS y otras shells/servicios de escritorio.
  services.upower.enable = true;

  # Paquetes exclusivos del entorno gráfico SDDM Catppuccin
  environment.systemPackages = with pkgs; [
    (catppuccin-sddm.override {
      flavor = "mocha";
      accent = "mauve";
      font  = "Noto Sans";
      fontSize = "9";
      loginBackground = true;
    })
  ];
}
