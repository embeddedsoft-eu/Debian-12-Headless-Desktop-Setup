# 🖥️ Debian 12 Headless Desktop Setup

[![Debian](https://img.shields.io/badge/Debian-12-blue.svg)](https://www.debian.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-5.0+-green.svg)](https://www.gnu.org/software/bash/)

> Automated setup script for a headless Debian 12 server with a graphical environment (Xorg, Openbox, XRDP, VNC) and Firefox for remote access via RDP or VNC.


```bash
git clone https://github.com/embeddedsoft-eu/Debian-12-Headless-Desktop-Setup.git
cd Debian-12-Headless-Desktop-Setup
sudo ./setup-headless-desktop.sh


## Features

- **Xorg** with dummy display — no physical monitor required
- **Openbox** — lightweight window manager
- **XRDP** — primary remote access (port 3389) with xserver-xorg-core support
- **TigerVNC** — fallback remote access (port 5901)
- **Firefox** — optional installation (not auto-started to prevent multiple instances)
- **Automatic user creation** with sudo privileges
- **Firewall configuration** (UFW) with necessary ports opened
- **Full logging** to /var/log/headless-setup/
- **Multi-architecture support**: x86_64, ARM64, ARMv7
- **Flexible command-line arguments**

## Quick Start

Clone the repository and run the script with root privileges. After completion, connect to the server via RDP or VNC.

## Command-Line Arguments

| Option | Description | Default Value |
|--------|-------------|---------------|
| --user NAME | Username | grabelu |
| --password PASS | User password | SecurePass123! |
| --vnc-password PASS | VNC password | VncPass123! |
| --resolution WxH | Screen resolution | 1920x1080 |
| --no-firefox | Skip Firefox installation | false |
| --verbose | Enable verbose output (debug mode) | false |
| --help | Show help message | — |

### Usage Examples

Basic run with default settings:
- Run the script with default parameters

Custom configuration:
- Specify custom username, password, VNC password, and resolution
- Optionally skip Firefox installation

Debug mode:
- Run with verbose output for troubleshooting

## Connecting to the Server

After installation, the script will display connection information.

### RDP (Recommended)
- Address: server-ip:3389
- Username: grabelu (or custom username)
- Password: SecurePass123! (or custom password)

### VNC (Fallback)
- Address: server-ip:5901
- Password: VncPass123! (or custom password)

## Logging

All installation logs are saved to /var/log/headless-setup/setup-YYYYMMDD-HHMMSS.log

### Viewing Logs in Real-Time
- Use tail -f to monitor log file

### Checking Service Status
- Check xrdp service status
- Check vncserver service status
- View xrdp journal logs

## Troubleshooting

### 1. RDP Won't Connect

Verify that the xrdp service is running and the port is open. If you encounter the error "There is no X server active on display", the script automatically installs xserver-xorg-core, which resolves this issue.

### 2. VNC Won't Start

Check the service status and start manually if needed with the correct geometry and localhost settings.

### 3. Firefox Doesn't Start Automatically

By default, Firefox is not started automatically to prevent multiple windows opening with each connection. Launch it manually from the terminal in your RDP or VNC session, or add it to ~/.config/openbox/autostart if automatic startup is needed.

### 4. Non-Standard Screen Resolution

For resolutions other than 1920x1080, the script attempts to generate a Modeline automatically using cvt. If that's insufficient, generate a Modeline manually and update the /etc/X11/xorg.conf file accordingly.

## Repository Structure

- setup-headless-desktop.sh - Main installation script
- README.md - This file
- LICENSE - MIT License

## License

This project is distributed under the MIT License. See the LICENSE file for details.

## Contributing

If you find a bug or have an improvement suggestion, please open an Issue or Pull Request.

## Author

embeddedsoft-eu
