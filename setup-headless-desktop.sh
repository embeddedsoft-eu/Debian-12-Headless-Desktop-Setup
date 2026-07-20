#!/bin/bash

# ============================================================
# Debian 12 Headless Desktop Setup Script
# 
# Installs Xorg dummy display, Openbox, XRDP and TigerVNC
# 
# Usage: sudo ./setup-headless-desktop.sh [OPTIONS]
# 
# Options:
#   --user NAME          Set username (default: grabelu)
#   --password PASS      Set user password (default: SecurePass123!)
#   --vnc-password PASS  Set VNC password (default: VncPass123!)
#   --resolution WxH     Set screen resolution (default: 1920x1080)
#   --no-firefox         Skip Firefox installation
#   --verbose            Enable verbose output
#   --help               Show this help message
# ============================================================

set -e

# ===== CONFIGURATION =====
# Default values
USER_NAME="grabelu"
USER_PASSWORD="SecurePass123!"
VNC_PASSWORD="VncPass123!"
SCREEN_WIDTH="1920"
SCREEN_HEIGHT="1080"
DISPLAY_NUMBER="1"  # VNC display number (1 = port 5901)
INSTALL_FIREFOX=true

# Logging
LOG_DIR="/var/log/headless-setup"
LOG_FILE="$LOG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
VERBOSE=false

# ===== COLOR CODES =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ===== FUNCTIONS =====

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    echo "[SUCCESS] $1" >> "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}→${NC} $1"
    echo "[INFO] $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    echo "[WARNING] $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    echo "[ERROR] $1" >> "$LOG_FILE"
}

print_header() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "[HEADER] $1" >> "$LOG_FILE"
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "This script must be run as root or with sudo."
        echo "Try: sudo $0"
        exit 1
    fi
}

check_architecture() {
    local arch=$(uname -m)
    print_info "Detected architecture: $arch"
    
    case $arch in
        x86_64)
            print_success "Architecture supported: x86_64"
            return 0
            ;;
        aarch64|arm64)
            print_warning "ARM64 architecture detected. Some packages may differ."
            print_info "Continuing with ARM64 compatibility..."
            return 0
            ;;
        armv7l|armhf)
            print_warning "ARMv7 architecture detected. Limited package support."
            return 0
            ;;
        *)
            print_error "Unsupported architecture: $arch"
            print_error "This script is designed for x86_64, ARM64, and ARMv7 systems."
            exit 1
            ;;
    esac
}

check_os_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ]; then
            print_success "OS: $PRETTY_NAME"
            return 0
        else
            print_warning "OS: $PRETTY_NAME"
            print_warning "This script is optimized for Debian 12, but may work on Ubuntu."
        fi
    else
        print_warning "Could not detect OS version."
    fi
}

setup_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    
    # Redirect stdout and stderr to log file
    exec > >(tee -a "$LOG_FILE") 2>&1
    
    print_info "Log file: $LOG_FILE"
}

show_help() {
    cat << EOF
Usage: sudo $0 [OPTIONS]

Debian 12 Headless Desktop Setup Script

Options:
  --user NAME          Set username (default: grabelu)
  --password PASS      Set user password (default: SecurePass123!)
  --vnc-password PASS  Set VNC password (default: VncPass123!)
  --resolution WxH     Set screen resolution (default: 1920x1080)
                       NOTE: Only 1920x1080 is fully supported.
                       Other resolutions may require manual Modeline generation.
  --no-firefox         Skip Firefox installation
  --verbose            Enable verbose output
  --help               Show this help message

Example:
  sudo $0 --user myuser --password MyPass123 --resolution 2560x1440 --no-firefox

EOF
    exit 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --user)
                USER_NAME="$2"
                shift 2
                ;;
            --password)
                USER_PASSWORD="$2"
                shift 2
                ;;
            --vnc-password)
                VNC_PASSWORD="$2"
                shift 2
                ;;
            --resolution)
                SCREEN_WIDTH="${2%x*}"
                SCREEN_HEIGHT="${2#*x}"
                if [ "$SCREEN_WIDTH" != "1920" ] || [ "$SCREEN_HEIGHT" != "1080" ]; then
                    print_warning "Non-standard resolution detected: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
                    print_warning "Modeline is optimized for 1920x1080 only."
                    print_warning "You may need to generate a custom Modeline using 'cvt'."
                fi
                shift 2
                ;;
            --no-firefox)
                INSTALL_FIREFOX=false
                shift
                ;;
            --verbose)
                VERBOSE=true
                set -x
                shift
                ;;
            --help)
                show_help
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                ;;
        esac
    done
    
    print_info "Configuration:"
    print_info "  User: $USER_NAME"
    print_info "  Resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
    print_info "  VNC Display: :${DISPLAY_NUMBER} (port: $((5900 + DISPLAY_NUMBER)))"
    print_info "  Install Firefox: $INSTALL_FIREFOX"
    echo ""
}

install_packages() {
    local packages=("$@")
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            print_info "Installing: $pkg"
            apt install -y "$pkg"
        else
            print_info "Package already installed: $pkg"
        fi
    done
}

# ===== MAIN INSTALLATION =====

# Parse command line arguments
parse_arguments "$@"

# Setup logging and root check
setup_logging
check_root
check_os_version
check_architecture

print_header "Debian 12 Headless Desktop Setup Starting..."

# ===== SYSTEM UPDATE =====

print_info "Updating system..."
apt update && apt upgrade -y
print_success "System updated"

# ===== BASE PACKAGES =====

print_info "Installing base packages..."
BASE_PACKAGES=("sudo" "curl" "wget" "ufw" "net-tools" "x11-utils" "dbus-x11" "xauth")
install_packages "${BASE_PACKAGES[@]}"
print_success "Base packages installed"

# ===== USER CREATION =====

print_info "Creating user: $USER_NAME"
if ! id "$USER_NAME" &>/dev/null; then
    adduser --disabled-password --gecos "" "$USER_NAME"
    echo "$USER_NAME:$USER_PASSWORD" | chpasswd
    usermod -aG sudo "$USER_NAME"
    print_success "User $USER_NAME created"
else
    print_info "User $USER_NAME already exists, skipping..."
fi

# ===== XORG + OPENBOX =====

print_info "Installing Xorg and Openbox..."
XORG_PACKAGES=("xorg" "xserver-xorg-video-dummy" "openbox")
install_packages "${XORG_PACKAGES[@]}"
print_success "Xorg and Openbox installed"

# ===== FIREFOX (Optional) =====

if [ "$INSTALL_FIREFOX" = true ]; then
    print_info "Installing Firefox..."
    apt install -y firefox-esr
    print_success "Firefox installed"
else
    print_info "Skipping Firefox installation (--no-firefox flag set)"
fi

# ===== DUMMY MONITOR CONFIGURATION =====

print_info "Configuring dummy monitor (${SCREEN_WIDTH}x${SCREEN_HEIGHT})..."

# Generate Modeline using cvt if available
MODELINE=""
if command -v cvt >/dev/null 2>&1; then
    # Remove "Modeline" prefix from cvt output
    MODELINE=$(cvt $SCREEN_WIDTH $SCREEN_HEIGHT 60 | grep "Modeline" | sed 's/^Modeline //')
    print_info "Generated Modeline: $MODELINE"
else
    # Fallback to default Modeline for 1920x1080
    MODELINE="\"${SCREEN_WIDTH}x${SCREEN_HEIGHT}\" 172.80 ${SCREEN_WIDTH} 2040 2248 2576 ${SCREEN_HEIGHT} 1081 1084 1118"
    print_warning "cvt not found. Using fallback Modeline for ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
fi

cat > /etc/X11/xorg.conf <<EOF
Section "Device"
    Identifier  "dummy_videocard"
    Driver      "dummy"
    VideoRam    256000
    Option      "ConstantDPI" "true"
EndSection

Section "Monitor"
    Identifier  "dummy_monitor"
    HorizSync   5.0 - 1000.0
    VertRefresh 5.0 - 200.0
    Modeline $MODELINE
EndSection

Section "Screen"
    Identifier  "default_screen"
    Device      "dummy_videocard"
    Monitor     "dummy_monitor"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
    EndSubSection
EndSection
EOF
print_success "Dummy monitor configured"

# ===== OPENBOX SESSION =====

print_info "Configuring Openbox session..."
cat > /home/$USER_NAME/.xsession <<EOF
exec openbox-session
EOF
chown $USER_NAME:$USER_NAME /home/$USER_NAME/.xsession
chmod 644 /home/$USER_NAME/.xsession
print_success "Openbox session configured"

# ===== OPENBOX AUTOSTART =====
# NOTE: Firefox is NOT started automatically to avoid multiple instances
# on each RDP/VNC connection. User can launch it manually.

print_info "Configuring Openbox autostart..."
mkdir -p /home/$USER_NAME/.config/openbox
cat > /home/$USER_NAME/.config/openbox/autostart <<'EOF'
# Startup applications for Openbox
# Add your applications here if needed
# Example: firefox &
# Note: Firefox is NOT started automatically to prevent multiple instances
EOF
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.config
print_success "Openbox autostart configured"

# ===== XRDP INSTALLATION =====

print_info "Installing and configuring XRDP..."
# IMPORTANT: xserver-xorg-core is required for RDP to work on headless systems
XRDP_PACKAGES=("xrdp" "xorgxrdp" "xserver-xorg-core")
install_packages "${XRDP_PACKAGES[@]}"
adduser xrdp ssl-cert 2>/dev/null || true
systemctl enable xrdp
systemctl restart xrdp

if systemctl is-active --quiet xrdp; then
    print_success "XRDP installed and running"
else
    print_warning "XRDP service may not be running. Check with: systemctl status xrdp"
fi

# ===== TIGERVNC INSTALLATION =====

print_info "Installing and configuring TigerVNC..."
VNC_PACKAGES=("tigervnc-standalone-server" "tigervnc-tools")
install_packages "${VNC_PACKAGES[@]}"

sudo -u $USER_NAME mkdir -p /home/$USER_NAME/.vnc

# Set VNC password automatically
echo "$VNC_PASSWORD" | vncpasswd -f | sudo -u $USER_NAME tee /home/$USER_NAME/.vnc/passwd > /dev/null
sudo -u $USER_NAME chmod 600 /home/$USER_NAME/.vnc/passwd

# Create xstartup file
cat > /home/$USER_NAME/.vnc/xstartup <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec openbox-session
EOF

chmod +x /home/$USER_NAME/.vnc/xstartup
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.vnc
print_success "TigerVNC configured"

# ===== VNC SYSTEMD SERVICE =====

print_info "Creating VNC systemd service..."
cat > /etc/systemd/system/vncserver@.service <<EOF
[Unit]
Description=TigerVNC server for display :%i
After=network.target

[Service]
Type=forking
User=$USER_NAME
WorkingDirectory=/home/$USER_NAME
PIDFile=/home/$USER_NAME/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
# -localhost no: listen on all interfaces for remote connections
ExecStart=/usr/bin/vncserver :%i -geometry ${SCREEN_WIDTH}x${SCREEN_HEIGHT} -depth 24 -localhost no
ExecStop=/usr/bin/vncserver -kill :%i
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vncserver@${DISPLAY_NUMBER}.service
systemctl start vncserver@${DISPLAY_NUMBER}.service

if systemctl is-active --quiet vncserver@${DISPLAY_NUMBER}.service; then
    print_success "VNC service started on display :${DISPLAY_NUMBER}"
else
    print_warning "VNC service may not be running. Check with: systemctl status vncserver@${DISPLAY_NUMBER}.service"
fi

# ===== FIREWALL CONFIGURATION =====

print_info "Configuring firewall..."
ufw allow 3389/tcp   # RDP
VNC_PORT=$((5900 + DISPLAY_NUMBER))
ufw allow ${VNC_PORT}/tcp   # VNC (dynamic port based on display number)
ufw --force enable

if ufw status | grep -q "Status: active"; then
    print_success "Firewall configured and active"
    print_info "  RDP: 3389/tcp"
    print_info "  VNC: ${VNC_PORT}/tcp"
else
    print_warning "Firewall may not be active. Check with: ufw status"
fi

# ===== SYSTEM CLEANUP =====

print_info "Cleaning up..."
apt autoremove -y
print_success "Cleanup completed"

# ===== SUMMARY =====

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "Unknown")
DATE=$(date)

clear
print_header "Installation Completed Successfully!"

echo -e "${CYAN}📡 SERVER INFORMATION${NC}"
echo "   Server IP: $SERVER_IP"
echo "   Date: $DATE"
echo "   Log File: $LOG_FILE"
echo ""

echo -e "${GREEN}🖥️  RDP CONNECTION (Recommended)${NC}"
echo "   Address:   $SERVER_IP:3389"
echo "   Username:  $USER_NAME"
echo "   Password:  $USER_PASSWORD"
echo ""

echo -e "${GREEN}🖥️  VNC CONNECTION (Backup)${NC}"
echo "   Address:   $SERVER_IP:${VNC_PORT}"
echo "   Password:  $VNC_PASSWORD"
echo "   Display:   :${DISPLAY_NUMBER}"
echo ""

echo -e "${YELLOW}📝 NEXT STEPS${NC}"
echo "   1. Connect via RDP using Windows Remote Desktop or any RDP client"
echo "   2. Or use any VNC client (port ${VNC_PORT})"
echo "   3. Firefox is NOT started automatically (launch manually if needed)"
echo ""

echo -e "${CYAN}🔧 USEFUL COMMANDS${NC}"
echo "   Check logs:     tail -f $LOG_FILE"
echo "   Check services: systemctl status xrdp vncserver@${DISPLAY_NUMBER}.service"
echo "   Check firewall: ufw status"
echo "   Start Firefox:  sudo -u $USER_NAME env DISPLAY=:0 firefox &"
echo ""

echo "========================================"

# ===== END =====
