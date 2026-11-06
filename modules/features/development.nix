{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.myFeatures.development {
    # Let editor-downloaded language servers run on NixOS when they expect
    # the conventional Linux dynamic linker at /lib64/ld-linux-x86-64.so.2.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        openssl
        stdenv.cc.cc
      ];
    };

    # Editores, LSP de Nix y agentes AI a nivel sistema. Su configuración
    # de usuario (Zed, Claude, OpenCode, skills) vive en modules/home/programs
    # gated con el mismo flag vía osConfig.
    environment.systemPackages = with pkgs; [
      #zed-editor
      nil
      nixd
      vtsls
      # FIXME(2026-11-05): nixpkgs 1d06008 trae opencode 2.2.5 con el hash
      # de node_modules desactualizado (hash mismatch en el FOD). Quitar este
      # override y volver a `opencode` a secas cuando nixpkgs lo corrija.
      (opencode.overrideAttrs (old: {
        node_modules = old.node_modules.overrideAttrs {
          outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
        };
      }))
      claude-code
      # Entornos de desarrollo por proyecto (devenv.nix): paquetes, servicios
      # (Postgres, Mailpit...) y procesos con `devenv up`, integrado con direnv.
      devenv
    ];
  };
}
