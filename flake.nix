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
      
      # Definimos la VM
      nixos-vm = let
        # --- DEFINICIÓN DE VARIABLES ---
        monitorSettings = {
            name = "Virtual-1";
            width = 1920;
            height = 1080;
            refreshRate = 60;
            scale = 1.0;
        };
      in nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        
        # Pasamos variables a los módulos de NixOS (hardware, system, etc)
        specialArgs = { inherit inputs monitorSettings; };
        
        modules = [
          ./hosts/vm/default.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            
            # Pasamos variables a los módulos de Home Manager (niri, alacritty, etc)
            home-manager.extraSpecialArgs = { inherit inputs monitorSettings; };
            
            home-manager.users.chunchoc = import ./modules/home/default.nix;
          }
        ];
      };

    };
  };
}