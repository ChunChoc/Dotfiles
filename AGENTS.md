# Agent Guide

## Repo Shape
- `flake.nix` is the real entrypoint. `mkHost` defines each NixOS target and passes `monitorSettings` into both NixOS modules and Home Manager.
- Host targets are `thinkpad`, `aorus`, and `nixos-vm`; the VM target uses folder `hosts/vm`, not `hosts/nixos-vm`.
- Keep host files focused on machine decisions: hardware imports, hostname, `myFeatures`, and host-specific quirks.
- Shared system config lives in `modules/core` and `modules/desktop.nix`; feature flags live in `modules/features` behind `lib.mkIf config.myFeatures.*`.
- User config lives in `modules/home`; static dotfiles are linked from `modules/home/dotfiles`, while files needing host variables are generated with `xdg.configFile.*.text` in `modules/home/default.nix`.

## Modularity Rules
- Prefer adding a feature module under `modules/features` plus an option in `lib/options.nix` instead of hard-coding host-specific packages in multiple hosts.
- Add new hosts through `flake.nix` using `mkHost`; pass display data via `monitorSettings` instead of duplicating monitor KDL.
- Do not convert static config files to Nix strings unless they need Nix values; this repo intentionally keeps most Niri/DMS KDL as standalone files.
- Keep wallpapers/assets outside config modules; Home Manager should install them, not inline them.
- Do not read or edit secrets: `.secrets`, `.env*`, SSH keys, GPG/PKI material, cloud credentials, or private key files.

## Niri and DMS
- `modules/home/dotfiles/niri/config.kdl` is the Niri orchestrator; DMS-related Niri modules live in `modules/home/dotfiles/niri/dms/*.kdl`.
- `niri/monitors.kdl` is generated from `monitorSettings`; `niri/dms/outputs.kdl` is currently generated from Home Manager too.
- Niri accepts only one top-level `layout {}` node; do not add another active `layout {}` in `colors.kdl` or another include.
- Theme direction is Catppuccin Mocha/Mauve with subtle glass/blur. Keep blur selective for shells/terminal surfaces; avoid global opacity/blur on browsers, editors, and content-heavy apps.
- DMS defaults are applied by the Home Manager user service `dms-session-defaults`; it sets the default wallpaper only when the current one is missing and forces dark mode.

## Commands
- Build the active host before claiming system config works: `nix build '.#nixosConfigurations.thinkpad.config.system.build.toplevel'`.
- Build Home Manager activation when changing user dotfiles: `nix build '.#nixosConfigurations.thinkpad.config.home-manager.users.chunchoc.home.activationPackage'`.
- Validate live Niri config after KDL changes: `niri validate --config ~/.config/niri/config.kdl`.
- Apply on the current machine with sudo/run0: `sudo nixos-rebuild switch --flake ~/Dotfiles#$(hostname)`.
- Apply a specific target with: `sudo nixos-rebuild switch --flake ~/Dotfiles#thinkpad`, `#aorus`, or `#nixos-vm`.
- `nix flake check` may fail while `nixos-vm` lacks a declared root filesystem; use targeted `nix build` commands unless fixing that VM issue.

## Workflow Gotchas
- `hardware-configuration.nix` is machine-generated; `thinkpad` has one, while `aorus` and `vm` currently leave it commented for install-time generation.
- The development feature installs OpenCode config from `modules/home/dotfiles/ai/opencode/opencode.json` and local agent skills; only edit it when changing the user's AI tooling.
- `update` and `upgrade` are Fish functions, not standalone scripts. They assume the repo is at `~/Dotfiles`.
- Home Manager uses `backupFileExtension = "backup"`; collisions may produce `.backup` files rather than overwriting silently.
- Do not commit build symlinks like `result`; they are artifacts from `nix build`.
