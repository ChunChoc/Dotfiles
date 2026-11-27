{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  opencodePackage = pkgs.callPackage ../../pkgs/opencode {
    upstream = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
  };
in
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
      nil
      nixd
      vtsls
      opencodePackage
      claude-code
      # Entornos de desarrollo por proyecto (devenv.nix): paquetes, servicios
      # (Postgres, Mailpit...) y procesos con `devenv up`, integrado con direnv.
      devenv
    ];
  };
}
