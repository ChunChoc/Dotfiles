{
  description = "Flake para NixOS Unstable + Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # herdr fijado al nixpkgs de 2026-09-28: con el de 2026-09-29 (GCC 16) su
    # libghostty-vt (Zig) deja un símbolo vacío y el enlace falla. Quitar esta
    # entrada y el uso en modules/home/packages.nix cuando nixpkgs lo arregle.
    nixpkgs-herdr.url = "github:nixos/nixpkgs/7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f";
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };
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

        # Thinkpad - trabajo y programación
        thinkpad = mkHost {
          hostname = "thinkpad";
          monitorSettings = {
            name = "eDP-1"; # Cambiar según tu monitor
            width = 1920;
            height = 1080;
            refreshRate = "60.001"; # el panel reporta 60.001 Hz; con "60" niri no lo encuentra
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

      };
    };
}
