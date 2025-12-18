# Smart TV Launcher for Raspberry Pi

Transform your Raspberry Pi 4 into a Smart TV with browser-based streaming apps and a family-friendly interface.

## 🎯 Project Goals

This repository provides automated setup scripts to turn a Raspberry Pi 4 running Raspberry Pi OS Bookworm into a fully functional Smart TV system. The setup is:

- **Automated**: Clone and run scripts - no manual configuration needed
- **Idempotent**: Safe to re-run scripts without breaking existing setup
- **Family-friendly**: Designed for non-technical users (wife, kids)
- **Reproducible**: Wipe your Pi and rebuild from scratch in minutes

## 📋 Requirements

- **Hardware**: Raspberry Pi 4 (4GB RAM recommended)
- **OS**: Raspberry Pi OS Bookworm (64-bit recommended)
- **Network**: Internet connection (WiFi or Ethernet)
- **Display**: HDMI-compatible TV or monitor

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/YourUsername/smart-tv-launcher.git
cd smart-tv-launcher
```

### 2. Run Bootstrap Script

This installs system packages and prepares your Pi:

```bash
sudo ./scripts/01_bootstrap_pi.sh
```

This will:
- Update system packages
- Install Chromium browser
- Install CEC utilities for HDMI control
- Update certificates and firmware
- Clean up unnecessary packages

**Note**: If firmware is updated, you'll need to reboot before proceeding.

### 3. Install Applications

This installs the Smart TV app launchers:

```bash
./scripts/install_apps.sh
```

This will:
- Copy `.desktop` files to your applications menu
- Configure YouTube TV launcher
- Update the desktop database

### 4. Launch Your Apps

Find "YouTube TV" in your application menu under AudioVideo, or launch from terminal:

```bash
gtk-launch youtube-tv.desktop
```

## 📁 Repository Structure

```
smart-tv-launcher/
├── files/
│   └── desktop/
│       └── youtube-tv.desktop # YouTube TV launcher (Smart TV UI)
├── scripts/
│   ├── 01_bootstrap_pi.sh     # System setup script (run as root)
│   ├── 02_install_apps.sh     # App installation script
│   ├── 03_check_network.sh    # Network diagnostics
│   └── 04_check_cec.sh        # HDMI CEC testing
└── README.md                   # This file
```

## 🔧 Available Scripts

### System Setup

- **`01_bootstrap_pi.sh`** - Run first (requires sudo)
  - Updates system packages
  - Installs required software (Chromium, CEC utils, etc.)
  - Safe to re-run

### Application Management

- **`02_install_apps.sh`** - Install Smart TV apps
  - Installs `.desktop` launchers
  - Configures application menu entries
  - Backs up existing files before overwriting

### Diagnostics & Utilities

- **`03_check_network.sh`** - Network diagnostics
  - Tests internet connectivity
  - Checks DNS resolution
  - Tests streaming service accessibility
  - Reports WiFi signal strength

- **`04_check_cec.sh`** - HDMI CEC testing
  - Scans for CEC devices
  - Tests TV control commands
  - Provides troubleshooting information
  - Usage:
    - `./scripts/04_check_cec.sh scan` (default)
    - `./scripts/04_check_cec.sh test` (test TV power)
    - `./scripts/04_check_cec.sh interactive` (manual control)

## 📺 Available Apps

### YouTube TV
Full Smart TV interface for YouTube with remote control support.
- Launches in fullscreen/kiosk mode
- Uses Smart TV user-agent for optimized UI
- Keyboard/remote navigation

### Coming Soon
- YouTube Kids
- Browser-based streaming apps (Cineby, etc.)
- Custom launcher interface (Google TV style)

## 🛠️ Customization

### Adding New Apps

1. Create a `.desktop` file in the `files/desktop/` directory
2. Run `./scripts/02_install_apps.sh` to install
3. Find your app in the application menu

Example `.desktop` file:
```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=My App
Exec=chromium --app="https://example.com"
Icon=chromium-browser
Terminal=false
Categories=AudioVideo;Video;
```

### Modifying Existing Apps

Edit the `.desktop` files in `files/desktop/` directory, then re-run:
```bash
./scripts/02_install_apps.sh
```

## 🐛 Troubleshooting

### YouTube TV won't load
1. Check network connectivity: `./scripts/03_check_network.sh`
2. Verify Chromium is installed: `chromium --version`
3. Test URL manually: `chromium --app="https://www.youtube.com/tv"`

### CEC (TV remote control) not working
1. Run diagnostics: `./scripts/04_check_cec.sh`
2. Check TV settings - enable CEC (may be called Anynet+, Bravia Sync, etc.)
3. Verify `/boot/config.txt` doesn't have `hdmi_ignore_cec=1`
4. Try different HDMI port on TV

### Apps not appearing in menu
1. Re-run: `./scripts/02_install_apps.sh`
2. Restart your desktop environment (logout and login)
3. Check installation: `ls ~/.local/share/applications/`

### Network issues
- Run network diagnostics: `./scripts/03_check_network.sh`
- Check WiFi signal strength
- Verify router/modem connectivity
- Test with Ethernet if WiFi is unstable

## 🔄 Rebuilding from Scratch

If you need to reset your Pi:

1. Flash a fresh Raspberry Pi OS Bookworm image
2. Clone this repository
3. Run `sudo ./scripts/01_bootstrap_pi.sh`
4. Reboot if firmware was updated
5. Run `./scripts/02_install_apps.sh`
6. Done!

## 🎮 Usage Tips

### Keyboard Shortcuts (YouTube TV)
- **Arrow keys**: Navigate
- **Enter**: Select
- **Backspace**: Back
- **F11**: Toggle fullscreen
- **Ctrl+W**: Close window

### Remote Control
If your TV supports HDMI CEC, you can use your TV remote to control the Pi.

### Auto-start on Boot
To launch YouTube TV automatically on boot, add to autostart:
```bash
mkdir -p ~/.config/autostart
cp files/desktop/youtube-tv.desktop ~/.config/autostart/
```

## 🔮 Future Plans

- [ ] YouTube Kids launcher
- [ ] Additional streaming app launchers
- [ ] Custom Smart TV launcher UI (Google TV style)
- [ ] Auto-start configuration script
- [ ] Parental controls
- [ ] Screensaver/idle management
- [ ] Volume control integration

## 📝 Notes

- Scripts use `set -euo pipefail` for safety
- Files are backed up before overwriting (with `.bak` suffix)
- All operations are idempotent and safe to re-run
- Designed for Raspberry Pi OS Bookworm (may work on other versions)

## 🤝 Contributing

This is a personal project for family use, but suggestions and improvements are welcome!

## 📄 License

This project is provided as-is for personal use. Modify and adapt as needed for your setup.

## 🙏 Acknowledgments

Built for family movie nights and kids' entertainment on a budget-friendly Raspberry Pi setup.

---

**Made with ❤️ for family-friendly Smart TV experiences**
