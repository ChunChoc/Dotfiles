# DankMaterialShell Power Settings Design

## Goal

Persist the DankMaterialShell power and idle settings in the dotfiles so Home Manager applies them through `~/.config/DankMaterialShell/settings.json`.

## Source Of Truth

Home Manager already links `modules/home/dotfiles/DankMaterialShell/settings.json` to `DankMaterialShell/settings.json`. The implementation should update only this JSON file.

## Desired Behavior

When connected to AC power, DankMaterialShell should switch to the Performance power profile and leave idle actions disabled.

When running on battery, DankMaterialShell should switch to the Balanced power profile, lock after 5 minutes, turn off monitors after 5 minutes, and suspend after 10 minutes.

## DankMaterialShell Values

DankMaterialShell 1.4.6 stores idle timeouts in seconds and power profiles as numeric strings:

- `"0"`: Power Saver
- `"1"`: Balanced
- `"2"`: Performance

The settings should be:

- `acProfileName`: `"2"`
- `acMonitorTimeout`: `0`
- `acLockTimeout`: `0`
- `acSuspendTimeout`: `0`
- `batteryProfileName`: `"1"`
- `batteryMonitorTimeout`: `300`
- `batteryLockTimeout`: `300`
- `batterySuspendTimeout`: `600`
- `lockBeforeSuspend`: unchanged as `false`

## Validation

Validate that `settings.json` remains valid JSON after editing. No Nix module changes are required because the file is already linked by Home Manager.
