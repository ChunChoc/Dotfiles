{ pkgs, ... }:
{
  # Habilitar ZSH
  programs.zsh.enable = true;

  # Mi usuario con sus propiedades
  users.users.chunchoc = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
    shell = pkgs.zsh;
  };

  # Paquetes esenciales para cualquier terminal
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
  ];
}