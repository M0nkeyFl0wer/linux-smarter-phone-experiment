#!/bin/bash
#
# AIROS Quick Installer for OnePlus 7 Pro & Pixel 4a 5G
# One-command installation script with interactive setup
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Global variables
DEVICE=""
OS_CHOICE=""
WORK_DIR="$HOME/airos-installer"

# Banner
show_banner() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "╔═══════════════════════════════════════════════╗"
    echo "║                                               ║"
    echo "║            AIROS Quick Installer              ║"
    echo "║     AI-Powered Linux Phone OS with           ║"
    echo "║         Android App Compatibility             ║"
    echo "║                                               ║"
    echo "╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    local missing_tools=()
    
    # Check for required tools
    for tool in adb fastboot wget curl python3; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}Missing required tools: ${missing_tools[*]}${NC}"
        echo ""
        echo "Install them with:"
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "  sudo apt install android-tools-adb android-tools-fastboot wget curl python3"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  brew install android-platform-tools wget curl python3"
        fi
        
        exit 1
    fi
    
    echo -e "${GREEN}✓ All prerequisites installed${NC}"
}

# Device selection
select_device() {
    echo -e "${BOLD}Select your device:${NC}"
    echo "  1) OnePlus 7 Pro (recommended)"
    echo "  2) Pixel 4a 5G"
    echo "  3) Auto-detect"
    echo ""
    
    read -p "Enter choice [1-3]: " choice
    
    case $choice in
        1)
            DEVICE="oneplus7pro"
            echo -e "${GREEN}✓ Selected: OnePlus 7 Pro${NC}"
            ;;
        2)
            DEVICE="pixel4a5g"
            echo -e "${GREEN}✓ Selected: Pixel 4a 5G${NC}"
            ;;
        3)
            detect_device
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            select_device
            ;;
    esac
}

# Auto-detect connected device
detect_device() {
    echo -e "${YELLOW}Detecting connected device...${NC}"
    
    # Check if device is connected
    if ! adb devices | grep -q "device$"; then
        echo -e "${RED}No device connected. Please connect your phone with USB debugging enabled.${NC}"
        exit 1
    fi
    
    # Get device model
    MODEL=$(adb shell getprop ro.product.model | tr -d '\r')
    
    case "$MODEL" in
        *"GM1917"*|*"HD1917"*|*"OnePlus 7 Pro"*)
            DEVICE="oneplus7pro"
            echo -e "${GREEN}✓ Detected: OnePlus 7 Pro${NC}"
            ;;
        *"Pixel 4a (5G)"*|*"bramble"*)
            DEVICE="pixel4a5g"
            echo -e "${GREEN}✓ Detected: Pixel 4a 5G${NC}"
            ;;
        *)
            echo -e "${RED}Unknown device: $MODEL${NC}"
            echo "Please select manually:"
            select_device
            ;;
    esac
}

# OS selection
select_os() {
    echo ""
    echo -e "${BOLD}Select OS to install:${NC}"
    
    if [ "$DEVICE" == "oneplus7pro" ]; then
        echo "  1) PostmarketOS + AIROS (Most stable, recommended)"
        echo "  2) Ubuntu Touch + AIROS (Best UI, easiest)"
        echo "  3) Droidian + AIROS (Most desktop-like)"
        echo "  4) SailfishOS + AIROS (Good Android support)"
    else
        echo "  1) PostmarketOS + AIROS (Recommended)"
        echo "  2) Ubuntu Touch + AIROS"
        echo "  3) CalyxOS + AIROS Layer (Android-based)"
    fi
    
    echo ""
    read -p "Enter choice: " choice
    
    case $choice in
        1) OS_CHOICE="postmarketos" ;;
        2) OS_CHOICE="ubuntutouch" ;;
        3) 
            if [ "$DEVICE" == "oneplus7pro" ]; then
                OS_CHOICE="droidian"
            else
                OS_CHOICE="calyxos"
            fi
            ;;
        4)
            if [ "$DEVICE" == "oneplus7pro" ]; then
                OS_CHOICE="sailfish"
            else
                echo -e "${RED}Invalid choice${NC}"
                select_os
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            select_os
            ;;
    esac
    
    echo -e "${GREEN}✓ Selected: $OS_CHOICE${NC}"
}

# Check bootloader status
check_bootloader() {
    echo ""
    echo -e "${YELLOW}Checking bootloader status...${NC}"
    
    # Reboot to bootloader
    echo "Rebooting to bootloader..."
    adb reboot bootloader
    sleep 5
    
    # Check if bootloader is unlocked
    if fastboot getvar unlocked 2>&1 | grep -q "yes"; then
        echo -e "${GREEN}✓ Bootloader is already unlocked${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Bootloader is locked${NC}"
        echo ""
        echo -e "${BOLD}${RED}WARNING: Unlocking bootloader will ERASE ALL DATA!${NC}"
        echo ""
        read -p "Do you want to unlock the bootloader? [y/N]: " confirm
        
        if [[ $confirm == [yY] ]]; then
            unlock_bootloader
        else
            echo "Cannot continue with locked bootloader"
            fastboot reboot
            exit 1
        fi
    fi
}

# Unlock bootloader
unlock_bootloader() {
    echo -e "${YELLOW}Unlocking bootloader...${NC}"
    
    if [ "$DEVICE" == "oneplus7pro" ]; then
        fastboot oem unlock
    else
        fastboot flashing unlock
    fi
    
    echo -e "${GREEN}✓ Bootloader unlocked${NC}"
    echo "Device will reboot and wipe data..."
    sleep 10
}

# Create work directory
setup_work_dir() {
    echo ""
    echo -e "${YELLOW}Setting up work directory...${NC}"
    
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR"
    
    echo -e "${GREEN}✓ Work directory: $WORK_DIR${NC}"
}

# Install PostmarketOS
install_postmarketos() {
    echo ""
    echo -e "${BOLD}Installing PostmarketOS...${NC}"
    
    # Install pmbootstrap if needed
    if ! command -v pmbootstrap &> /dev/null; then
        echo "Installing pmbootstrap..."
        pip3 install --user pmbootstrap
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    # Configure pmbootstrap
    echo "Configuring PostmarketOS..."
    
    if [ "$DEVICE" == "oneplus7pro" ]; then
        DEVICE_CODENAME="oneplus-guacamole"
    else
        DEVICE_CODENAME="google-bramble"
    fi
    
    # Create config file
    cat > pmbootstrap.cfg << EOF
[pmbootstrap]
device = $DEVICE_CODENAME
user = user
ui = phosh
extra_packages = waydroid,openssh-server,neofetch
timezone = America/New_York
EOF
    
    # Initialize
    pmbootstrap --config pmbootstrap.cfg init
    
    # Build
    echo "Building PostmarketOS image..."
    pmbootstrap build
    
    # Install
    echo "Installing to device..."
    pmbootstrap install --rsync
    
    # Flash
    pmbootstrap flasher flash_kernel
    pmbootstrap flasher flash_rootfs
    
    echo -e "${GREEN}✓ PostmarketOS installed${NC}"
}

# Install Ubuntu Touch
install_ubuntutouch() {
    echo ""
    echo -e "${BOLD}Installing Ubuntu Touch...${NC}"
    
    # Download UBports installer
    if [ ! -f "ubports-installer" ]; then
        echo "Downloading UBports installer..."
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            wget https://github.com/ubports/ubports-installer/releases/latest/download/ubports-installer_linux_x86_64.AppImage
            chmod +x ubports-installer_*.AppImage
            INSTALLER="./ubports-installer_linux_x86_64.AppImage"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            wget https://github.com/ubports/ubports-installer/releases/latest/download/ubports-installer_mac.dmg
            # Mount and extract dmg
            echo "Please run the UBports installer manually from the downloaded DMG"
            exit 0
        fi
    fi
    
    # Run installer
    echo "Starting UBports installer..."
    $INSTALLER -f
    
    echo -e "${GREEN}✓ Ubuntu Touch installed${NC}"
}

# Install AIROS components
install_airos() {
    echo ""
    echo -e "${BOLD}Installing AIROS components...${NC}"
    
    # Wait for device to boot
    echo "Waiting for device to boot..."
    sleep 30
    
    # Detect connection method
    if ping -c 1 172.16.42.1 &> /dev/null; then
        DEVICE_IP="172.16.42.1"
        echo "Connected via USB networking"
    else
        echo "Please enter device IP address:"
        read DEVICE_IP
    fi
    
    # Download AIROS installer
    wget https://raw.githubusercontent.com/airos/main/install-airos-linux.sh
    
    # Copy to device and run
    echo "Installing AIROS on device..."
    scp install-airos-linux.sh user@$DEVICE_IP:/tmp/
    ssh user@$DEVICE_IP "chmod +x /tmp/install-airos-linux.sh && sudo /tmp/install-airos-linux.sh"
    
    # Get auth token
    AUTH_TOKEN=$(ssh user@$DEVICE_IP "sudo grep auth_token /etc/airos/airos.yml | cut -d: -f2 | tr -d ' '")
    
    echo -e "${GREEN}✓ AIROS installed${NC}"
    echo ""
    echo -e "${BOLD}Connection details:${NC}"
    echo "  IP Address: $DEVICE_IP"
    echo "  Auth Token: $AUTH_TOKEN"
}

# Post-installation setup
post_install_setup() {
    echo ""
    echo -e "${BOLD}Post-Installation Setup${NC}"
    echo ""
    
    # Create connection script
    cat > connect-to-airos.py << EOF
#!/usr/bin/env python3
import sys
sys.path.insert(0, '.')

from airos_client import AIROSClient

# Device connection details
DEVICE_IP = "$DEVICE_IP"
AUTH_TOKEN = "$AUTH_TOKEN"

# Connect to device
client = AIROSClient(DEVICE_IP, AUTH_TOKEN)

# Get system info
info = client.get_system_info()
print(f"Connected to {info.model} running AIROS {info.airos_version}")

# Install some essential apps
print("Installing essential apps...")
apps = ["F-Droid", "Firefox", "Signal"]
for app in apps:
    print(f"Installing {app}...")
    client.execute_command(f"airos-cli install '{app}'")

print("Setup complete!")
print(f"You can now control your device using this client")
EOF
    
    chmod +x connect-to-airos.py
    
    # Create quick command aliases
    cat > airos-commands.sh << EOF
# AIROS Quick Commands
alias airos-connect="python3 $WORK_DIR/connect-to-airos.py"
alias airos-ssh="ssh user@$DEVICE_IP"
alias airos-status="curl http://$DEVICE_IP:8080/api/system_info | python3 -m json.tool"
alias airos-install="curl -X POST -H 'Content-Type: application/json' http://$DEVICE_IP:8080/api/install_app -d"

echo "AIROS commands loaded. Try:"
echo "  airos-connect  - Connect Python client"
echo "  airos-ssh      - SSH to device"
echo "  airos-status   - Check status"
EOF
    
    echo -e "${GREEN}✓ Setup scripts created${NC}"
}

# Main installation flow
main() {
    show_banner
    check_prerequisites
    
    echo -e "${BOLD}Welcome to AIROS Quick Installer${NC}"
    echo ""
    echo "This installer will:"
    echo "  1. Install a Linux-based OS on your phone"
    echo "  2. Add Android app compatibility via Waydroid"
    echo "  3. Install MicroG for Google Services"
    echo "  4. Set up AI-powered app fixing"
    echo ""
    echo -e "${YELLOW}⚠ WARNING: This will REPLACE your phone's current OS${NC}"
    echo ""
    read -p "Continue? [y/N]: " confirm
    
    if [[ $confirm != [yY] ]]; then
        echo "Installation cancelled"
        exit 0
    fi
    
    select_device
    select_os
    check_bootloader
    setup_work_dir
    
    # Install selected OS
    case $OS_CHOICE in
        postmarketos)
            install_postmarketos
            ;;
        ubuntutouch)
            install_ubuntutouch
            ;;
        droidian)
            install_droidian
            ;;
        *)
            echo -e "${RED}OS installation not yet implemented: $OS_CHOICE${NC}"
            exit 1
            ;;
    esac
    
    # Install AIROS
    install_airos
    post_install_setup
    
    # Success message
    echo ""
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}    AIROS Installation Complete! 🎉${NC}"
    echo -e "${GREEN}${BOLD}═══════════════════════════════════════════════${NC}"
    echo ""
    echo "Your device is now running AIROS with:"
    echo "  ✓ Linux-based OS ($OS_CHOICE)"
    echo "  ✓ Android app support (Waydroid)"
    echo "  ✓ Google Services replacement (MicroG)"
    echo "  ✓ AI-powered app compatibility"
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo "  1. Source the command aliases:"
    echo "     source $WORK_DIR/airos-commands.sh"
    echo ""
    echo "  2. Connect to your device:"
    echo "     airos-connect"
    echo ""
    echo "  3. Install Android apps:"
    echo "     Open Aurora Store on the device"
    echo ""
    echo -e "${BOLD}Connection Details:${NC}"
    echo "  IP: $DEVICE_IP"
    echo "  Token: $AUTH_TOKEN"
    echo ""
    echo "Documentation: https://github.com/airos/wiki"
    echo "Support: https://discord.gg/airos"
    echo ""
    echo -e "${GREEN}Enjoy your AI-powered Linux phone!${NC}"
}

# Error handler
trap 'echo -e "${RED}Installation failed. Check the logs above for details.${NC}"; exit 1' ERR

# Run main function
main "$@"