# Agent Guide

## Repo Shape
- `flake.nix` is the real entrypoint. `mkHost` defines each NixOS target and passes `monitorSettings` into both NixOS modules and Home Manager.
- The only host target is `thinkpad`. Add new hosts through `mkHost` in `flake.nix` plus a folder in `hosts/`.
- Keep host files focused on machine decisions: hardware imports, hostname, `myFeatures`, and host-specific quirks. Networking basics, firewall, and `stateVersion` live in `modules/core/system.nix` with `lib.mkDefault`.
- Shared system config lives in `modules/core` and `modules/desktop.nix`; feature flags live in `modules/features` behind `lib.mkIf config.myFeatures.*`.
- User config lives in `modules/home` only — never write `home-manager.users.*` from `modules/features`. Home Manager modules read feature flags via `osConfig.myFeatures.*` (see `modules/home/packages.nix`, `modules/home/programs/ai.nix`).
- Static dotfiles are linked from `modules/home/dotfiles`, while files needing host variables are generated with `xdg.configFile.*.text` in `modules/home/default.nix`. The Neovim config is linked out-of-store (`mkOutOfStoreSymlink`) so lazy.nvim can write `lazy-lock.json`.

## Modularity Rules
- Prefer adding a feature module under `modules/features` plus an option in `lib/options.nix` instead of hard-coding host-specific packages in multiple hosts.
- Add new hosts through `flake.nix` using `mkHost`; pass display data via `monitorSettings` instead of duplicating monitor KDL.
- Do not convert static config files to Nix strings unless they need Nix values; this repo intentionally keeps most Niri/DMS KDL as standalone files.
- Keep wallpapers/assets outside config modules; Home Manager should install them, not inline them.
- Do not read or edit secrets: `.secrets`, `.env*`, SSH keys, GPG/PKI material, cloud credentials, or private key files.

## Niri and DMS
- `modules/home/dotfiles/niri/config.kdl` is the declarative Niri orchestrator. `modules/home/programs/dms.nix` seeds writable DMS settings and `niri/dms/*.kdl` from the dotfiles, preserving GUI edits on later activations.
- All monitor definitions live in writable `niri/dms/outputs.kdl`, seeded from `monitorSettings` and `externalOutputs`. The activation migrates legacy `niri/monitors.kdl` into it; do not add a competing static output definition that overrides GUI changes.
- Niri accepts only one top-level `layout {}` node; do not add another active `layout {}` in `colors.kdl` or another include.
- Theme direction is Catppuccin Mocha/Mauve with subtle glass/blur. Keep blur selective for shells/terminal surfaces; avoid global opacity/blur on browsers, editors, and content-heavy apps.
- Prefer DMS 2.x's native Material 3 Expressive implementation; do not restore the old QML patches for popup geometry, island surfaces/opacity, or spring presets without a confirmed need.
- DMS background blur is disabled pending an upstream fix for jagged bar/island edges. Do not add experimental blur-mask patches.
- DMS settings/session defaults are seed-only. Do not reintroduce login services that overwrite theme, wallpaper, night mode or transition choices. The wallpaper-accent generator remains independent of the selected DMS theme.
- Use the canonical `dms/` config/state/cache paths; `DankMaterialShell` is only a legacy compatibility alias. Templates live in `modules/home/dotfiles/dms/`.

## Commands
- Build the active host before claiming system config works: `nix build '.#nixosConfigurations.thinkpad.config.system.build.toplevel'`.
- Build Home Manager activation when changing user dotfiles: `nix build '.#nixosConfigurations.thinkpad.config.home-manager.users.chunchoc.home.activationPackage'`.
- Validate live Niri config after KDL changes: `niri validate --config ~/.config/niri/config.kdl`.
- Apply on the current machine with sudo/run0: `sudo nixos-rebuild switch --flake ~/Dotfiles#$(hostname)`.
- `nix flake check` should pass; run it after structural changes to the flake or modules.

## Workflow Gotchas
- `hardware-configuration.nix` is machine-generated per host; new hosts get theirs at install time.
- `modules/home/programs/ai.nix` (gated by the development feature) installs OpenCode config from `modules/home/dotfiles/ai/opencode/opencode.json` and shared agent skills from pinned flake inputs; only edit it when changing the user's AI tooling.
- `pkgs/` holds local derivations not in nixpkgs, loaded with `pkgs.callPackage`. `pkgs/hyperframes` (CLI + agent skills, gated by `myFeatures.hyperframes` in `modules/home/programs/hyperframes.nix`) pins the CLI version to the `hyperframes` flake input tag; bump both together per `pkgs/hyperframes/README.md`.
- `update` and `upgrade` are Fish functions, not standalone scripts. They assume the repo is at `~/Dotfiles`.
- Home Manager uses `backupFileExtension = "backup"`; collisions may produce `.backup` files rather than overwriting silently.
- Do not commit build symlinks like `result`; they are artifacts from `nix build`.
