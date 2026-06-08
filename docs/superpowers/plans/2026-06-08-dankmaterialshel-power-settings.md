# DankMaterialShell Power Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist DankMaterialShell AC and battery power behavior in the Home Manager-managed dotfiles.

**Architecture:** Home Manager already links `modules/home/dotfiles/DankMaterialShell/settings.json` into `~/.config/DankMaterialShell/settings.json`. The implementation only updates the existing JSON values used by DankMaterialShell 1.4.6 for power profiles and idle timeouts.

**Tech Stack:** Nix Home Manager, DankMaterialShell JSON configuration.

---

## File Structure

- Modify: `modules/home/dotfiles/DankMaterialShell/settings.json`
- Reference: `docs/superpowers/specs/2026-06-08-dankmaterialshel-power-settings-design.md`

## Tasks

### Task 1: Persist DankMaterialShell Power Settings

**Files:**
- Modify: `modules/home/dotfiles/DankMaterialShell/settings.json:151-161`

- [ ] **Step 1: Confirm current values**

Read `modules/home/dotfiles/DankMaterialShell/settings.json:151-161` and confirm the relevant fields currently exist:

```json
  "acMonitorTimeout": 0,
  "acLockTimeout": 0,
  "acSuspendTimeout": 0,
  "acSuspendBehavior": 0,
  "acProfileName": "",
  "batteryMonitorTimeout": 0,
  "batteryLockTimeout": 0,
  "batterySuspendTimeout": 0,
  "batterySuspendBehavior": 0,
  "batteryProfileName": "",
  "lockBeforeSuspend": false,
```

- [ ] **Step 2: Update the minimal JSON values**

Replace that block with:

```json
  "acMonitorTimeout": 0,
  "acLockTimeout": 0,
  "acSuspendTimeout": 0,
  "acSuspendBehavior": 0,
  "acProfileName": "2",
  "batteryMonitorTimeout": 300,
  "batteryLockTimeout": 300,
  "batterySuspendTimeout": 600,
  "batterySuspendBehavior": 0,
  "batteryProfileName": "1",
  "lockBeforeSuspend": false,
```

- [ ] **Step 3: Validate JSON syntax**

Run:

```bash
nix eval --impure --expr 'builtins.fromJSON (builtins.readFile ./modules/home/dotfiles/DankMaterialShell/settings.json)' >/dev/null
```

Expected: exit code `0` and no output.

- [ ] **Step 4: Inspect the resulting diff**

Run:

```bash
git diff -- modules/home/dotfiles/DankMaterialShell/settings.json docs/superpowers/specs/2026-06-08-dankmaterialshel-power-settings-design.md docs/superpowers/plans/2026-06-08-dankmaterialshel-power-settings.md
```

Expected: the settings diff only changes `acProfileName`, battery timeouts, and `batteryProfileName`; the docs diff contains the approved spec and this plan.

- [ ] **Step 5: Do not commit automatically**

Leave changes unstaged and uncommitted unless the user explicitly requests a commit.

## Self-Review

- Spec coverage: The plan covers AC Performance, battery Balanced, battery lock at 300 seconds, battery monitor off at 300 seconds, battery suspend at 600 seconds, and no AC idle actions.
- Placeholder scan: No placeholder tasks remain.
- Type consistency: Power profiles are numeric strings and timeouts are integers in seconds, matching DankMaterialShell 1.4.6 behavior.
