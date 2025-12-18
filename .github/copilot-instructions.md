# Copilot Instructions - Smart TV Launcher

## Overview

This repository automates the setup of a Raspberry Pi 4 into a reusable "Smart TV box." Any fresh Raspberry Pi OS (Bookworm) installation should be configurable by cloning this repo and running a small number of scripts.

### Assumptions

- **Target device**: Raspberry Pi 4 (4GB)
- **OS**: Raspberry Pi OS Bookworm (KMS video driver + NetworkManager)
- **Primary UI**: Components launched via Chromium
- **YouTube TV UI**: Requires a Smart TV user-agent
- **Future expansion**: YouTube Kids launcher, Cineby launcher, Google TV–style home launcher
- **Project must remain**: Idempotent, clean, and easy to re-run

## Repository Structure Requirements

The repository should follow this structure:

```
repo/
  files/
    desktop/
      youtube-tv.desktop        # .desktop entries for Smart TV apps
      # (future .desktop files will be added here)
  
  scripts/
    01_bootstrap_pi.sh          # installs system dependencies
    02_check_pi_settings.sh     # verifies network and CEC
    03_install_apps.sh          # installs .desktop launchers
  
  README.md
  .github/
    copilot-instructions.md
```

**Copilot should respect and maintain this structure.**

## Script Requirements

### General Rules (all scripts)

- Use Bash: `#!/usr/bin/env bash`
- Use strict mode: `set -euo pipefail`
- Use functions for clarity
- Use `$HOME` instead of hard-coded user paths
- Include clear logging (e.g., `echo "[INFO] ..."`)
- Scripts must be idempotent (safe to run multiple times)
- Provide helpful error messages if something is missing (e.g., Chromium, cec-client, permissions)
- Do not assume HDMI-CEC always works (the HDMI cable may not support CEC)

### scripts/01_bootstrap_pi.sh

Copilot should implement a bootstrap script that:

- Runs `sudo apt update` and `sudo apt upgrade -y`
- Installs required packages (checking before installing where possible):
  - `chromium` (Bookworm package name, not `chromium-browser`)
  - `cec-utils`
  - `ca-certificates`
  - `network-manager`
  - `git` (optional but useful)
- Runs `sudo update-ca-certificates`
- If `rpi-eeprom-update` exists, runs `sudo rpi-eeprom-update -a`
- Prints a summary at the end:
  - Which packages were installed or already present
  - Any notable errors
- The script must be safe to re-run

### scripts/02_check_pi_settings.sh

Copilot should implement a diagnostic script that:

- Checks system configuration:
  - Verifies Chromium is installed
- Checks network connectivity:
  - Tests internet connectivity (ping to common hosts)
  - Verifies DNS resolution
  - Shows network interface status
- Checks HDMI CEC:
  - Verifies `cec-client` is installed
  - Checks `/boot/config.txt` for `hdmi_ignore_cec` setting
  - Scans for CEC devices
- Provides a summary at the end with:
  - "All checks passed! Your Pi is ready."
  - Or specific guidance on what needs attention
- This script should be run after bootstrap to verify the Pi is ready

### scripts/03_install_apps.sh

Copilot should implement a script that:

- Copies all `.desktop` files from `files/desktop/` into: `$HOME/.local/share/applications/`
- Makes them executable with `chmod +x`
- Refreshes the desktop database: `update-desktop-database "$HOME/.local/share/applications"` (if available; handle missing command gracefully)
- Prints a summary of which desktop entries were installed or updated
- The script should be generic so future `.desktop` files added to `files/desktop/` are also installed

## Desktop Entry Requirements

### files/desktop/youtube-tv.desktop

Copilot should generate a `.desktop` file with at least:

- `Type`: Application
- `Name`: YouTube TV
- `Comment`: YouTube Smart TV Interface
- `Exec` line that launches Chromium in app mode with a Smart TV user-agent, for example:
  ```
  Exec=chromium --app="https://www.youtube.com/tv" --user-agent="Mozilla/5.0 (SMART-TV; Linux; Tizen 7.0) AppleWebKit/537.36 (KHTML, like Gecko) SamsungBrowser/2.1 TV Safari/537.36"
  ```
- `Icon`: web-browser (placeholder; can be changed later)
- `Terminal=false`
- `Categories=AudioVideo;Video;`

**Future .desktop files** (e.g., YouTube Kids, Cineby) should follow similar patterns.

## README Requirements

Copilot should generate a `README.md` that includes:

- A brief overview of the project (Raspberry Pi Smart TV automation)
- Hardware and software requirements
- Basic usage:
  ```bash
  git clone <repo-url>
  cd <repo>
  chmod +x scripts/*.sh
  sudo ./scripts/01_bootstrap_pi.sh
  ./scripts/02_check_pi_settings.sh
  ./scripts/03_install_apps.sh
  ```
- A note on what is currently implemented:
  - Base packages and YouTube TV launcher
  - Pi settings verification (network + CEC diagnostics)
- A short "Future work" section mentioning:
  - YouTube Kids launcher
  - Browser-based streaming app launcher (e.g., Cineby)
  - Smart TV home launcher (Google TV–style)
  - Auto-boot into launcher

## Copilot Behavior Expectations

### Copilot SHOULD:

- Generate maintainable, modular, and clearly commented Bash scripts
- Preserve and respect the existing repository structure
- Keep scripts idempotent and safe to re-run
- Favor clarity and robustness over cleverness

### Copilot should NOT:

- Invent new top-level folders without clear need
- Hardcode user paths like `/home/pi` (prefer `$HOME`)
- Add heavy or unnecessary dependencies
- Assume HDMI-CEC or WiFi always work

## Future Work (Context Only)

Not implemented yet, but Copilot should be aware that the repo will later:

- Add `.desktop` entries for:
  - YouTube Kids
  - Browser-based streaming apps (e.g., Cineby)
- Add a custom Google TV–style launcher (likely HTML/Python/GTK or similar)
- Add scripts to:
  - Auto-start the launcher on boot
  - Optionally lock down the environment for non-technical family members

These should be designed to integrate cleanly with the current `files/` and `scripts/` layout.
