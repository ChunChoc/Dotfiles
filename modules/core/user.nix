{ pkgs, ... }:
{
  # Habilitar Fish
  programs.fish.enable = true;

  # Mi usuario con sus propiedades
  users.users.chunchoc = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
    shell = pkgs.fish;
  };

  # Paquetes esenciales para cualquier terminal
  environment.systemPackages = with pkgs; [
    vim
  ];
}
