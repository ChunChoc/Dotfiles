{
  description = "Flake para NixOS Unstable + Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      # Función helper para crear configuraciones de host
      mkHost =
        { hostname, monitorSettings, externalOutputs ? [ ] }:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";

          specialArgs = { inherit inputs monitorSettings externalOutputs; };

          modules = [
            ./hosts/${hostname}/default.nix

            # Módulos comunes a todos los hosts
            ./lib/options.nix
            ./modules/core
            ./modules/features
            ./modules/desktop.nix

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { inherit inputs monitorSettings externalOutputs; };
              home-manager.users.chunchoc = import ./modules/home/default.nix;
            }
          ];
        };
    in
    {
      nixosConfigurations = {

        # VM de desarrollo
        nixos-vm = mkHost {
          hostname = "vm";
          monitorSettings = {
            name = "Virtual-1";
            width = 1920;
            height = 1080;
            refreshRate = 60;
            scale = 1.0;
          };
        };

        # Thinkpad - trabajo y programación
        thinkpad = mkHost {
          hostname = "thinkpad";
          monitorSettings = {
            name = "eDP-1"; # Cambiar según tu monitor
            width = 1920;
            height = 1080;
            refreshRate = 60;
            scale = 1.2;
          };
          externalOutputs = [
            {
              name = "PNP(AOC) 24G50F 2S7R9HA004013";
              mode = "1920x1080@120";
              scale = 1;
            }
          ];
        };

        # Aorus - gaming y desarrollo ocasional
        aorus = mkHost {
          hostname = "aorus";
          monitorSettings = {
            name = "eDP-1"; # Cambiar según tu monitor
            width = 1920;
            height = 1080;
            refreshRate = 144; # 144Hz probablemente
            scale = 1.0;
          };
        };

      };
    };
}
