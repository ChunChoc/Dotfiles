{ pkgs, ... }:
{
  # Habilitar Fish
  programs.fish.enable = true;

  # Mi usuario con sus propiedades
  users.users.chunchoc = {
    isNormalUser = true;
    # "libvirtd" lo añade el feature virtualization solo cuando está activo.
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
