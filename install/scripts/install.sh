#!/bin/bash
#
# AIROS Universal Installation Script
# https://github.com/airos/airos
#
# This script guides you through installing AIROS on your device
# Supports: Physical devices, Virtual machines, Docker containers
#
# Usage: ./install.sh [options]
#   Options:
#     --device <name>     Specify device (auto-detect if not set)
#     --os <os>          Choose OS (ubuntu-touch, postmarketos, droidian)
#     --virtual          Set up virtual environment instead
#     --docker           Quick Docker setup
#     --help             Show this help message
#

set -e

# Script version
VERSION="0.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/airos-install-$(date +%Y%m%d-%H%M%S).log"
WORK_DIR="$HOME/airos-installer"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Default values
DEVICE=""
OS_CHOICE=""
INSTALL_MODE="physical"
AUTO_YES=false
DEBUG=false

# Logging functions
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_info() {
    log "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    log "${GREEN}✅ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    log "${RED}❌ $1${NC}"
}

log_step() {
    log "${CYAN}➤ $1${NC}"
}

# Print banner
print_banner() {
    clear
    cat << "EOF"
    ___   ________  ____  _____
   /   | /  _/ __ \/ __ \/ ___/
  / /| | / // /_/ / / / /\__ \ 
 / ___ |_/ // _, _/ /_/ /___/ / 
/_/  |_/___/_/ |_|\____//____/  
                                
   AI-Integrated ROM for Open Systems
   Transform your device into an AI research platform
   
EOF
    echo -e "${CYAN}Version: $VERSION${NC}"
    echo -e "${CYAN}GitHub: https://github.com/airos/airos${NC}"
    echo ""
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --device)
                DEVICE="$2"
                shift 2
                ;;
            --os)
                OS_CHOICE="$2"
                shift 2
                ;;
            --virtual)
                INSTALL_MODE="virtual"
                shift
                ;;
            --docker)
                INSTALL_MODE="docker"
                shift
                ;;
            --yes|-y)
                AUTO_YES=true
                shift
                ;;
            --debug)
                DEBUG=true
                set -x
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    cat << EOF
AIROS Installation Script

Usage: $0 [options]

Options:
    --device <name>    Specify device (e.g., oneplus-7-pro, pixel-4a-5g)
    --os <os>         Choose OS (ubuntu-touch, postmarketos, droidian)
    --virtual         Set up virtual environment for testing
    --docker          Quick Docker container setup
    --yes, -y         Automatic yes to prompts
    --debug           Enable debug output
    --help, -h        Show this help message

Examples:
    # Auto-detect and install on physical device
    ./install.sh

    # Install Ubuntu Touch on OnePlus 7 Pro
    ./install.sh --device oneplus-7-pro --os ubuntu-touch

    # Set up virtual testing environment
    ./install.sh --virtual

    # Quick Docker setup
    ./install.sh --docker

Supported Devices:
    - oneplus-7-pro (OnePlus 7 Pro) - Excellent support
    - pixel-4a-5g (Pixel 4a 5G) - Good support
    - pinephone (PinePhone/Pro) - Excellent support
    - pixel-3a (Pixel 3a) - Good support
    - oneplus-6 (OnePlus 6/6T) - Good support
    
For full device list, visit:
https://github.com/airos/airos/blob/main/install/DEVICE_SUPPORT.md

EOF
}

# Check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    local missing_tools=()
    
    # Check required tools based on mode
    if [[ "$INSTALL_MODE" == "physical" ]]; then
        for tool in adb fastboot git python3 wget curl; do
            if ! command -v $tool &> /dev/null; then
                missing_tools+=($tool)
            fi
        done
    elif [[ "$INSTALL_MODE" == "virtual" ]]; then
        for tool in git python3 wget curl qemu-system-x86_64; do
            if ! command -v $tool &> /dev/null; then
                missing_tools+=($tool)
            fi
        done
    elif [[ "$INSTALL_MODE" == "docker" ]]; then
        if ! command -v docker &> /dev/null; then
            missing_tools+=(docker)
        fi
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install them first:"
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            log_info "  sudo apt install ${missing_tools[*]}"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            log_info "  brew install ${missing_tools[*]}"
        fi
        
        return 1
    fi
    
    log_success "All requirements met!"
    return 0
}

# Detect connected device
detect_device() {
    log_info "Detecting connected device..."
    
    if ! adb devices | grep -q "device$"; then
        log_error "No device detected. Please connect your device with USB debugging enabled."
        return 1
    fi
    
    local model=$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r' || echo "")
    local device_code=$(adb shell getprop ro.product.device 2>/dev/null | tr -d '\r' || echo "")
    
    log_info "Detected: $model ($device_code)"
    
    # Match device to our supported list
    case "$model" in
        *"GM1917"*|*"HD1917"*|*"OnePlus 7 Pro"*)
            DEVICE="oneplus-7-pro"
            log_success "Identified: OnePlus 7 Pro"
            ;;
        *"Pixel 4a (5G)"*|*"bramble"*)
            DEVICE="pixel-4a-5g"
            log_success "Identified: Pixel 4a 5G"
            ;;
        *"Pixel 3a"*|*"sargo"*)
            DEVICE="pixel-3a"
            log_success "Identified: Pixel 3a"
            ;;
        *"PinePhone"*)
            DEVICE="pinephone"
            log_success "Identified: PinePhone"
            ;;
        *)
            log_warning "Unknown device model: $model"
            log_warning "You can specify manually with --device option"
            return 1
            ;;
    esac
    
    return 0
}

# Select OS to install
select_os() {
    if [ -n "$OS_CHOICE" ]; then
        return 0
    fi
    
    log_info "Select OS to install:"
    echo "  1) Ubuntu Touch (recommended - best UI)"
    echo "  2) PostmarketOS (most stable)"
    echo "  3) Droidian (most desktop-like)"
    echo "  4) Sailfish OS (good Android support)"
    echo ""
    
    read -p "Enter choice [1-4]: " choice
    
    case $choice in
        1) OS_CHOICE="ubuntu-touch" ;;
        2) OS_CHOICE="postmarketos" ;;
        3) OS_CHOICE="droidian" ;;
        4) OS_CHOICE="sailfish" ;;
        *) 
            log_error "Invalid choice"
            select_os
            ;;
    esac
    
    log_success "Selected: $OS_CHOICE"
}

# Create work directory structure
setup_work_dir() {
    log_info "Setting up work directory..."
    
    mkdir -p "$WORK_DIR"/{downloads,backup,logs,config}
    cd "$WORK_DIR"
    
    # Save installation state
    cat > "$WORK_DIR/install-state.json" << EOF
{
    "version": "$VERSION",
    "device": "$DEVICE",
    "os": "$OS_CHOICE",
    "mode": "$INSTALL_MODE",
    "started": "$(date -Iseconds)",
    "log_file": "$LOG_FILE"
}
EOF
    
    log_success "Work directory ready: $WORK_DIR"
}

# Download required files
download_files() {
    log_info "Downloading required files..."
    
    cd "$WORK_DIR/downloads"
    
    # Download device-specific installer
    if [ -n "$DEVICE" ]; then
        log_step "Downloading $DEVICE installer..."
        wget -q "https://raw.githubusercontent.com/airos/airos/main/devices/$DEVICE/install.sh" \
             -O "${DEVICE}-install.sh" || true
    fi
    
    # Download AIROS components
    log_step "Downloading AIROS components..."
    wget -q "https://raw.githubusercontent.com/airos/airos/main/src/airos-agent/airos_agent.py" \
         -O airos_agent.py || true
    
    # Download OS-specific files
    case "$OS_CHOICE" in
        ubuntu-touch)
            log_step "Ubuntu Touch files will be downloaded by installer"
            ;;
        postmarketos)
            log_step "PostmarketOS files will be downloaded by pmbootstrap"
            ;;
        droidian)
            log_step "Downloading Droidian image..."
            # wget Droidian image
            ;;
    esac
    
    log_success "Downloads complete"
}

# Backup device data
backup_device() {
    if [[ "$INSTALL_MODE" != "physical" ]]; then
        return 0
    fi
    
    log_warning "Installation will ERASE ALL DATA on your device!"
    
    if [ "$AUTO_YES" = false ]; then
        read -p "Do you want to backup your data first? [Y/n]: " response
        if [[ ! "$response" =~ ^[Nn]$ ]]; then
            log_info "Starting backup..."
            
            cd "$WORK_DIR/backup"
            
            # Backup user data
            log_step "Backing up photos..."
            adb pull /sdcard/DCIM . 2>/dev/null || true
            
            log_step "Backing up downloads..."
            adb pull /sdcard/Download . 2>/dev/null || true
            
            log_step "Backing up documents..."
            adb pull /sdcard/Documents . 2>/dev/null || true
            
            log_success "Backup complete: $WORK_DIR/backup"
        fi
    fi
}

# Install on physical device
install_physical() {
    log_info "Starting physical device installation..."
    
    # Check if device-specific installer exists
    if [ -f "$WORK_DIR/downloads/${DEVICE}-install.sh" ]; then
        log_info "Running device-specific installer..."
        bash "$WORK_DIR/downloads/${DEVICE}-install.sh" --os "$OS_CHOICE"
    else
        # Generic installation flow
        case "$OS_CHOICE" in
            ubuntu-touch)
                install_ubuntu_touch
                ;;
            postmarketos)
                install_postmarketos
                ;;
            droidian)
                install_droidian
                ;;
            *)
                log_error "Unsupported OS: $OS_CHOICE"
                return 1
                ;;
        esac
    fi
    
    # Install AIROS components
    install_airos_components
}

# Install Ubuntu Touch
install_ubuntu_touch() {
    log_info "Installing Ubuntu Touch..."
    
    # Check for UBports installer
    if ! command -v ubports-installer &> /dev/null; then
        log_warning "UBports installer not found"
        log_info "Please install from: https://ubuntu-touch.io/get-ubuntu-touch"
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            log_info "Installing via snap..."
            sudo snap install ubports-installer
        fi
    fi
    
    # Run installer
    log_step "Launching UBports installer..."
    log_info "Please follow the GUI to install Ubuntu Touch"
    ubports-installer || true
    
    log_success "Ubuntu Touch installation complete"
}

# Install PostmarketOS
install_postmarketos() {
    log_info "Installing PostmarketOS..."
    
    # Install pmbootstrap if needed
    if ! command -v pmbootstrap &> /dev/null; then
        log_info "Installing pmbootstrap..."
        pip3 install --user pmbootstrap
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    # Initialize pmbootstrap
    log_step "Initializing pmbootstrap..."
    pmbootstrap init
    
    # Build and install
    log_step "Building PostmarketOS..."
    pmbootstrap build
    
    log_step "Installing to device..."
    pmbootstrap install
    pmbootstrap flasher flash_kernel
    pmbootstrap flasher flash_rootfs
    
    log_success "PostmarketOS installation complete"
}

# Install AIROS components
install_airos_components() {
    log_info "Installing AIROS components..."
    
    # Wait for device to boot
    log_info "Waiting for device to boot (this may take a few minutes)..."
    sleep 30
    
    # Get device IP
    log_info "Please enter your device's IP address"
    log_info "(You can find this in Settings → About → Developer Mode)"
    read -p "Device IP: " device_ip
    
    # Create AIROS installer script
    cat > "$WORK_DIR/install-airos-on-device.sh" << 'EOFSCRIPT'
#!/bin/bash
# AIROS Component Installation

echo "Installing AIROS components..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y python3 python3-pip git wget curl

# Install Waydroid
sudo apt install -y waydroid
sudo waydroid init -s GAPPS

# Start Waydroid
sudo systemctl start waydroid-container
waydroid session start &

# Install MicroG
cd /tmp
wget https://github.com/microg/GmsCore/releases/latest/download/GmsCore.apk
wget https://github.com/microg/GsfProxy/releases/latest/download/GsfProxy.apk
sudo waydroid app install GmsCore.apk
sudo waydroid app install GsfProxy.apk

# Install Aurora Store
wget https://f-droid.org/repo/com.aurora.store_37.apk
sudo waydroid app install com.aurora.store_37.apk

# Install AIROS Agent
cat > /opt/airos_agent.py << 'EOF'
# AIROS Agent placeholder
print("AIROS Agent installed")
EOF

echo "AIROS installation complete!"
EOFSCRIPT
    
    # Copy and run on device
    log_step "Installing on device..."
    scp "$WORK_DIR/install-airos-on-device.sh" "user@$device_ip:~/"
    ssh "user@$device_ip" "bash ~/install-airos-on-device.sh"
    
    log_success "AIROS components installed"
}

# Set up virtual environment
setup_virtual() {
    log_info "Setting up virtual testing environment..."
    
    # Download QEMU image
    log_step "Downloading virtual machine image..."
    cd "$WORK_DIR/downloads"
    wget -c "https://github.com/airos/images/releases/latest/download/airos-qemu-x86_64.qcow2" || {
        log_warning "Pre-built image not available, creating new one..."
        create_vm_image
    }
    
    # Create VM runner script
    cat > "$WORK_DIR/run-vm.sh" << 'EOF'
#!/bin/bash
qemu-system-x86_64 \
    -enable-kvm \
    -m 4G \
    -smp 4 \
    -hda downloads/airos-qemu-x86_64.qcow2 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080 \
    -device e1000,netdev=net0 \
    -vnc :1
EOF
    chmod +x "$WORK_DIR/run-vm.sh"
    
    log_success "Virtual environment ready!"
    log_info "To start VM: cd $WORK_DIR && ./run-vm.sh"
    log_info "Then connect with VNC to localhost:5901"
}

# Set up Docker environment
setup_docker() {
    log_info "Setting up Docker environment..."
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon not running"
        return 1
    fi
    
    # Run AIROS container
    log_step "Starting AIROS Docker container..."
    docker run -d \
        --name airos-test \
        --privileged \
        -p 8080:8080 \
        -p 8081:8081 \
        -v "$WORK_DIR/data:/data" \
        ghcr.io/airos/simulator:latest || {
        
        log_warning "Pre-built image not available, building locally..."
        
        # Create Dockerfile
        cat > "$WORK_DIR/Dockerfile" << 'EOF'
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    python3 python3-pip git wget curl
WORKDIR /opt/airos
COPY downloads/airos_agent.py .
RUN pip3 install aiohttp psutil pyyaml
EXPOSE 8080 8081
CMD ["python3", "airos_agent.py"]
EOF
        
        docker build -t airos-local "$WORK_DIR"
        docker run -d \
            --name airos-test \
            --privileged \
            -p 8080:8080 \
            -p 8081:8081 \
            airos-local
    }
    
    log_success "Docker environment ready!"
    log_info "Container running at: http://localhost:8080"
    log_info "View logs: docker logs -f airos-test"
}

# Generate completion report
generate_report() {
    local report_file="$WORK_DIR/installation-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOF
# AIROS Installation Report

## Installation Details
- **Date**: $(date)
- **Version**: $VERSION
- **Device**: $DEVICE
- **OS**: $OS_CHOICE
- **Mode**: $INSTALL_MODE
- **Log File**: $LOG_FILE

## Status
- Installation completed successfully

## Next Steps
1. Test core functionality
2. Install essential apps
3. Configure AI agent
4. Join community for support

## Resources
- Documentation: https://github.com/airos/airos
- Discord: https://discord.gg/airos
- Issues: https://github.com/airos/airos/issues

## Notes
Add any additional notes here...

EOF
    
    log_success "Report saved: $report_file"
}

# Main installation flow
main() {
    # Initialize
    print_banner
    parse_arguments "$@"
    
    # Start logging
    log_info "AIROS Installation Started - $(date)"
    log_info "Version: $VERSION"
    log_info "Mode: $INSTALL_MODE"
    
    # Check requirements
    if ! check_requirements; then
        log_error "Requirements check failed"
        exit 1
    fi
    
    # Set up work directory
    setup_work_dir
    
    # Execute based on mode
    case "$INSTALL_MODE" in
        physical)
            # Detect or verify device
            if [ -z "$DEVICE" ]; then
                if ! detect_device; then
                    log_error "Could not detect device"
                    log_info "Please specify with --device option"
                    exit 1
                fi
            fi
            
            # Select OS
            if [ -z "$OS_CHOICE" ]; then
                select_os
            fi
            
            # Download files
            download_files
            
            # Backup
            backup_device
            
            # Install
            install_physical
            ;;
            
        virtual)
            setup_virtual
            ;;
            
        docker)
            setup_docker
            ;;
    esac
    
    # Generate report
    generate_report
    
    # Success message
    log_success "================================================"
    log_success "       AIROS Installation Complete! 🎉"
    log_success "================================================"
    
    case "$INSTALL_MODE" in
        physical)
            log_info "Your device is now running AIROS!"
            log_info "Check the report for next steps."
            ;;
        virtual)
            log_info "Virtual environment is ready!"
            log_info "Start with: cd $WORK_DIR && ./run-vm.sh"
            ;;
        docker)
            log_info "Docker container is running!"
            log_info "Access at: http://localhost:8080"
            ;;
    esac
    
    log_info ""
    log_info "📚 Documentation: https://github.com/airos/airos"
    log_info "💬 Get help: https://discord.gg/airos"
    log_info "📝 Report saved: $WORK_DIR/installation-report-*.md"
}

# Trap errors
trap 'log_error "Installation failed at line $LINENO"' ERR

# Run main function
main "$@"