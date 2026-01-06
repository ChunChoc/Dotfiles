{
  description = "Flake para NixOS Unstable + Home Manager";

  inputs = {
    # CRUCIAL: Mantener esto en 'nixos-unstable' como dice la documentación
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations = {
      # Asegúrate que 'nixos-vm' coincida con networking.hostName en configuration.nix
      nixos-vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
	    home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.chunchoc = import ./home-manager/home.nix; # CAMBIA 'tu_usuario'
          }
        ];
      };
    };
  };
}
