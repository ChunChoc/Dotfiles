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
      zed-editor
      nil
      nixd
      opencode
      claude-code
    ];
  };
}
