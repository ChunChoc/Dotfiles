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

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
