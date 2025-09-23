#!/bin/bash
#
# AIROS Linux Installation Script
# Installs AI-powered mobile OS with Android app compatibility
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AIROS_VERSION="0.1.0-alpha"
INSTALL_DIR="/opt/airos"
CONFIG_DIR="/etc/airos"
DATA_DIR="/var/lib/airos"
LOG_DIR="/var/log/airos"

# Detect distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        echo -e "${RED}Cannot detect OS distribution${NC}"
        exit 1
    fi
}

# Print banner
print_banner() {
    echo -e "${GREEN}"
    echo "================================================"
    echo "     AIROS Linux Installation Script"
    echo "     Version: $AIROS_VERSION"
    echo "================================================"
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root (use sudo)${NC}"
        exit 1
    fi
}

# Check system requirements
check_requirements() {
    echo -e "${YELLOW}Checking system requirements...${NC}"
    
    # Check RAM (minimum 3GB)
    total_ram=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    if [ $total_ram -lt 3000000 ]; then
        echo -e "${RED}Warning: Less than 3GB RAM detected${NC}"
    fi
    
    # Check disk space (minimum 16GB free)
    free_space=$(df / | awk 'NR==2 {print $4}')
    if [ $free_space -lt 16000000 ]; then
        echo -e "${RED}Warning: Less than 16GB free disk space${NC}"
    fi
    
    # Check kernel version
    kernel_version=$(uname -r)
    echo "Kernel version: $kernel_version"
    
    # Check if running on supported device
    if [ -f /proc/device-tree/model ]; then
        device_model=$(cat /proc/device-tree/model)
        echo "Device model: $device_model"
    fi
}

# Install dependencies
install_dependencies() {
    echo -e "${YELLOW}Installing dependencies...${NC}"
    
    case $OS in
        ubuntu|debian)
            apt update
            apt install -y \
                python3 python3-pip python3-venv \
                git curl wget \
                build-essential cmake meson ninja-build \
                libglib2.0-dev libgtk-3-dev \
                libwayland-dev libxkbcommon-dev \
                android-tools-adb android-tools-fastboot \
                apktool apksigner \
                sqlite3 \
                iptables dnsmasq \
                systemd-container
            ;;
        arch|manjaro)
            pacman -Syu --noconfirm
            pacman -S --noconfirm \
                python python-pip \
                git curl wget \
                base-devel cmake meson ninja \
                wayland libxkbcommon \
                android-tools \
                apktool \
                sqlite \
                iptables dnsmasq \
                systemd
            ;;
        fedora)
            dnf install -y \
                python3 python3-pip \
                git curl wget \
                gcc gcc-c++ make cmake meson ninja-build \
                wayland-devel libxkbcommon-devel \
                android-tools \
                apktool \
                sqlite \
                iptables dnsmasq \
                systemd-container
            ;;
        postmarketos)
            apk add \
                python3 py3-pip \
                git curl wget \
                build-base cmake meson ninja \
                wayland-dev libxkbcommon-dev \
                android-tools \
                sqlite \
                iptables dnsmasq
            ;;
        *)
            echo -e "${RED}Unsupported distribution: $OS${NC}"
            exit 1
            ;;
    esac
}

# Install Python packages
install_python_packages() {
    echo -e "${YELLOW}Installing Python packages...${NC}"
    
    python3 -m pip install --upgrade pip
    python3 -m pip install \
        aiohttp \
        psutil \
        pyyaml \
        watchdog \
        dbus-python \
        requests \
        websocket-client
}

# Install Waydroid
install_waydroid() {
    echo -e "${YELLOW}Installing Waydroid...${NC}"
    
    # Check if already installed
    if command -v waydroid &> /dev/null; then
        echo "Waydroid already installed"
        return
    fi
    
    case $OS in
        ubuntu|debian)
            curl -s https://repo.waydro.id/waydroid.gpg | apt-key add -
            echo "deb https://repo.waydro.id/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/waydroid.list
            apt update
            apt install -y waydroid
            ;;
        arch|manjaro)
            yay -S waydroid --noconfirm || {
                # Fallback to manual build
                git clone https://aur.archlinux.org/waydroid.git /tmp/waydroid
                cd /tmp/waydroid
                makepkg -si --noconfirm
            }
            ;;
        fedora)
            dnf copr enable aleasto/waydroid -y
            dnf install -y waydroid
            ;;
        postmarketos)
            apk add waydroid waydroid-nftables
            ;;
        *)
            # Generic installation from source
            git clone https://github.com/waydroid/waydroid /tmp/waydroid
            cd /tmp/waydroid
            python3 setup.py install
            ;;
    esac
    
    # Initialize Waydroid with GAPPS (will be replaced with MicroG)
    waydroid init -s GAPPS -f
}

# Install MicroG in Waydroid
install_microg() {
    echo -e "${YELLOW}Installing MicroG...${NC}"
    
    MICROG_DIR="/tmp/microg"
    mkdir -p $MICROG_DIR
    cd $MICROG_DIR
    
    # Download MicroG components
    echo "Downloading MicroG components..."
    
    # Latest releases URLs (update as needed)
    MICROG_CORE="https://github.com/microg/GmsCore/releases/latest/download/com.google.android.gms-*.apk"
    GSF_PROXY="https://github.com/microg/GsfProxy/releases/latest/download/GsfProxy.apk"
    FAKE_STORE="https://github.com/microg/FakeStore/releases/latest/download/FakeStore.apk"
    
    # Download APKs
    wget -O GmsCore.apk $(curl -s https://api.github.com/repos/microg/GmsCore/releases/latest | grep browser_download_url | cut -d '"' -f 4)
    wget -O GsfProxy.apk $(curl -s https://api.github.com/repos/microg/GsfProxy/releases/latest | grep browser_download_url | cut -d '"' -f 4)
    wget -O FakeStore.apk $(curl -s https://api.github.com/repos/microg/FakeStore/releases/latest | grep browser_download_url | cut -d '"' -f 4)
    
    # Install as system apps in Waydroid
    echo "Installing MicroG as system apps..."
    
    WAYDROID_DATA="/var/lib/waydroid"
    SYSTEM_PRIV_APP="$WAYDROID_DATA/overlay/system/priv-app"
    
    # Create directories
    mkdir -p "$SYSTEM_PRIV_APP/GmsCore"
    mkdir -p "$SYSTEM_PRIV_APP/GsfProxy"
    mkdir -p "$SYSTEM_PRIV_APP/FakeStore"
    
    # Copy APKs
    cp GmsCore.apk "$SYSTEM_PRIV_APP/GmsCore/"
    cp GsfProxy.apk "$SYSTEM_PRIV_APP/GsfProxy/"
    cp FakeStore.apk "$SYSTEM_PRIV_APP/FakeStore/"
    
    # Set permissions
    chmod -R 755 "$SYSTEM_PRIV_APP"
    
    # Enable signature spoofing (requires patched framework)
    echo "Enabling signature spoofing..."
    install_signature_spoofing
    
    cd -
    rm -rf $MICROG_DIR
}

# Install signature spoofing support
install_signature_spoofing() {
    echo -e "${YELLOW}Installing signature spoofing support...${NC}"
    
    # Download NanoDroid patcher
    PATCHER_URL="https://github.com/Nanolx/NanoDroid/releases/latest/download/NanoDroid-patcher-*.zip"
    wget -O /tmp/patcher.zip $(curl -s https://api.github.com/repos/Nanolx/NanoDroid/releases/latest | grep "NanoDroid-patcher" | grep browser_download_url | cut -d '"' -f 4)
    
    # Extract and apply
    unzip -o /tmp/patcher.zip -d /tmp/patcher/
    
    # Apply to Waydroid system
    WAYDROID_IMG="/var/lib/waydroid/images/system.img"
    if [ -f "$WAYDROID_IMG" ]; then
        # Mount system image
        mkdir -p /tmp/waydroid_system
        mount -o loop,rw "$WAYDROID_IMG" /tmp/waydroid_system
        
        # Apply patches
        /tmp/patcher/META-INF/com/google/android/update-binary dummy 1 /tmp/patcher.zip
        
        # Unmount
        umount /tmp/waydroid_system
    fi
    
    rm -rf /tmp/patcher /tmp/patcher.zip
}

# Install Aurora Store
install_aurora_store() {
    echo -e "${YELLOW}Installing Aurora Store...${NC}"
    
    # Download latest Aurora Store
    AURORA_URL=$(curl -s https://api.github.com/repos/Aurora-Store/AuroraStore/releases/latest | grep browser_download_url | grep apk | cut -d '"' -f 4)
    
    if [ -n "$AURORA_URL" ]; then
        wget -O /tmp/AuroraStore.apk "$AURORA_URL"
        
        # Install in Waydroid
        waydroid app install /tmp/AuroraStore.apk
        
        rm /tmp/AuroraStore.apk
    else
        echo -e "${RED}Failed to download Aurora Store${NC}"
    fi
}

# Install AIROS components
install_airos() {
    echo -e "${YELLOW}Installing AIROS components...${NC}"
    
    # Create directories
    mkdir -p $INSTALL_DIR
    mkdir -p $CONFIG_DIR
    mkdir -p $DATA_DIR
    mkdir -p $LOG_DIR
    
    # Copy AIROS agent
    cp airos_linux_agent.py $INSTALL_DIR/
    chmod +x $INSTALL_DIR/airos_linux_agent.py
    
    # Create configuration
    cat > $CONFIG_DIR/airos.yml << EOF
version: $AIROS_VERSION
agent:
  port: 8080
  ws_port: 8081
  auth_token: $(uuidgen)
  
waydroid:
  auto_start: true
  memory_limit: 2G
  
microg:
  enabled: true
  services:
    gcm: true
    location: true
    maps: true
    
app_fixer:
  auto_fix: true
  monitor_crashes: true
  patch_on_install: true
  
security:
  allow_root_commands: true
  network_isolation: false
EOF
    
    # Create systemd service
    cat > /etc/systemd/system/airos-agent.service << EOF
[Unit]
Description=AIROS Linux Agent
After=network.target waydroid-container.service
Wants=waydroid-container.service

[Service]
Type=simple
ExecStart=/usr/bin/python3 $INSTALL_DIR/airos_linux_agent.py
Restart=always
RestartSec=10
User=root
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
EOF
    
    # Create helper scripts
    cat > /usr/local/bin/airos-cli << 'EOF'
#!/bin/bash
# AIROS CLI Tool

AGENT_URL="http://localhost:8080/api"

case $1 in
    status)
        curl -s $AGENT_URL/system_info | python3 -m json.tool
        ;;
    install)
        curl -X POST -H "Content-Type: application/json" \
            -d "{\"apk_url\":\"$2\", \"pre_patch\":true}" \
            $AGENT_URL/install_app
        ;;
    fix)
        curl -X POST -H "Content-Type: application/json" \
            -d "{\"package_name\":\"$2\"}" \
            $AGENT_URL/fix_app
        ;;
    exec)
        shift
        curl -X POST -H "Content-Type: application/json" \
            -d "{\"command\":\"$*\"}" \
            $AGENT_URL/execute
        ;;
    *)
        echo "Usage: airos-cli {status|install|fix|exec} [args]"
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/airos-cli
    
    # Create app compatibility database
    sqlite3 $DATA_DIR/app_fixes.db < /dev/null
    
    echo -e "${GREEN}AIROS components installed${NC}"
}

# Configure firewall
configure_firewall() {
    echo -e "${YELLOW}Configuring firewall...${NC}"
    
    # Allow AIROS agent ports
    iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
    iptables -I INPUT -p tcp --dport 8081 -j ACCEPT
    
    # Save rules
    case $OS in
        ubuntu|debian)
            apt install -y iptables-persistent
            netfilter-persistent save
            ;;
        arch|manjaro)
            iptables-save > /etc/iptables/iptables.rules
            systemctl enable iptables
            ;;
        fedora)
            firewall-cmd --permanent --add-port=8080/tcp
            firewall-cmd --permanent --add-port=8081/tcp
            firewall-cmd --reload
            ;;
    esac
}

# Start services
start_services() {
    echo -e "${YELLOW}Starting services...${NC}"
    
    # Reload systemd
    systemctl daemon-reload
    
    # Start Waydroid
    systemctl enable waydroid-container
    systemctl start waydroid-container
    
    # Wait for Waydroid to initialize
    sleep 10
    
    # Start AIROS agent
    systemctl enable airos-agent
    systemctl start airos-agent
    
    # Check status
    systemctl status airos-agent --no-pager
}

# Print completion message
print_completion() {
    echo -e "${GREEN}"
    echo "================================================"
    echo "     AIROS Linux Installation Complete!"
    echo "================================================"
    echo -e "${NC}"
    
    # Get auth token
    AUTH_TOKEN=$(grep auth_token $CONFIG_DIR/airos.yml | cut -d: -f2 | tr -d ' ')
    
    echo "Agent URL: http://localhost:8080"
    echo "Auth Token: $AUTH_TOKEN"
    echo ""
    echo "Quick commands:"
    echo "  airos-cli status         - Check system status"
    echo "  airos-cli install <url>  - Install APK with auto-fix"
    echo "  airos-cli fix <package>  - Fix app compatibility"
    echo ""
    echo "To connect from AI agent:"
    echo "  from airos_client import AIROSClient"
    echo "  client = AIROSClient('localhost', '$AUTH_TOKEN')"
    echo ""
    echo -e "${YELLOW}Note: First boot of Waydroid may take several minutes${NC}"
}

# Main installation flow
main() {
    print_banner
    check_root
    detect_distro
    check_requirements
    
    echo -e "${GREEN}Installing AIROS Linux for $OS $VER${NC}"
    echo ""
    
    install_dependencies
    install_python_packages
    install_waydroid
    install_microg
    install_aurora_store
    install_airos
    configure_firewall
    start_services
    
    print_completion
}

# Run main function
main "$@"