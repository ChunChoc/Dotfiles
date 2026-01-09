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