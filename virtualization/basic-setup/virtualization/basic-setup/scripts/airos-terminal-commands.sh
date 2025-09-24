#!/bin/bash

# AIROS Terminal Commands - Friendly interface for virtual environment

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Emojis for fun
ROBOT="🤖"
PHONE="📱"
GEAR="⚙️"
CHECK="✅"
CROSS="❌"
ROCKET="🚀"

airos_status() {
    echo -e "\n${CYAN}${GEAR} AIROS System Status${NC}"
    echo "=============================="

    # Check if agent is running
    if pgrep -f "airos_agent.py" > /dev/null; then
        echo -e "${CHECK} AI Agent: ${GREEN}Running${NC}"
    else
        echo -e "${CROSS} AI Agent: ${RED}Stopped${NC}"
    fi

    # System info
    echo -e "${BLUE}CPU Usage:${NC} $(python3 -c "import psutil; print(f'{psutil.cpu_percent()}%')")"
    echo -e "${BLUE}Memory:${NC} $(python3 -c "import psutil; print(f'{psutil.virtual_memory().percent}%')")"

    # Mock Waydroid status
    echo -e "${BLUE}Waydroid:${NC} ${GREEN}Simulated (Virtual Mode)${NC}"
    echo -e "${BLUE}Installed Apps:${NC} 3 demo apps"
    echo -e "${BLUE}Fixes Applied:${NC} 0 (ready to test)"

    echo ""
}

airos_start() {
    echo -e "\n${ROCKET} Starting AIROS AI Agent..."
    echo "================================"

    if pgrep -f "airos_agent.py" > /dev/null; then
        echo -e "${YELLOW}Agent already running!${NC}"
        return
    fi

    # Start the agent in background
    cd /opt/airos/src/airos-agent
    python3 airos_agent_virtual.py > /var/log/airos/agent.log 2>&1 &

    echo -e "${CHECK} Agent starting..."
    sleep 2

    if pgrep -f "airos_agent" > /dev/null; then
        echo -e "${CHECK} ${GREEN}AI Agent is now running!${NC}"
        echo -e "${BLUE}API:${NC} http://localhost:8080"
        echo -e "${BLUE}WebSocket:${NC} ws://localhost:8081"
        echo -e "${BLUE}Logs:${NC} tail -f /var/log/airos/agent.log"
    else
        echo -e "${CROSS} ${RED}Failed to start agent${NC}"
    fi
    echo ""
}

airos_stop() {
    echo -e "\n${GEAR} Stopping AIROS AI Agent..."
    pkill -f "airos_agent"
    echo -e "${CHECK} ${GREEN}Agent stopped${NC}\n"
}

airos_monitor() {
    echo -e "\n${ROBOT} AIROS Agent Activity Monitor"
    echo "=============================="
    echo "Press Ctrl+C to exit"
    echo ""

    # Start monitoring
    if [ -f /var/log/airos/agent.log ]; then
        tail -f /var/log/airos/agent.log
    else
        echo -e "${YELLOW}No log file found. Start the agent first.${NC}"
    fi
}

airos_demo() {
    echo -e "\n${PHONE} AIROS Demo Scenarios"
    echo "====================="
    echo "Choose a demo:"
    echo "1. Install and fix WhatsApp compatibility"
    echo "2. Handle missing Google Services"
    echo "3. Fix native library issue"
    echo "4. Permission error resolution"
    echo "5. Full app compatibility test"
    echo ""
    read -p "Enter choice (1-5): " choice

    case $choice in
        1) demo_whatsapp ;;
        2) demo_google_services ;;
        3) demo_native_library ;;
        4) demo_permissions ;;
        5) demo_full_test ;;
        *) echo "Invalid choice" ;;
    esac
}

demo_whatsapp() {
    echo -e "\n${PHONE} WhatsApp Compatibility Demo"
    echo "============================="
    echo "Simulating WhatsApp installation and fixing..."

    # Simulate install
    echo -e "${BLUE}[INSTALL]${NC} Downloading WhatsApp APK..."
    sleep 1
    echo -e "${BLUE}[INSTALL]${NC} Installing in Waydroid..."
    sleep 1
    echo -e "${YELLOW}[ISSUE]${NC} Google Services dependency detected"
    sleep 1
    echo -e "${ROBOT}[AI FIX]${NC} Analyzing compatibility issue..."
    sleep 2
    echo -e "${ROBOT}[AI FIX]${NC} Applying MicroG patch..."
    sleep 1
    echo -e "${CHECK} ${GREEN}WhatsApp successfully patched and working!${NC}"
    echo ""
}

demo_google_services() {
    echo -e "\n${GEAR} Google Services Compatibility Demo"
    echo "==================================="
    echo "Simulating Google Services dependency fix..."

    echo -e "${BLUE}[DETECT]${NC} App requires com.google.android.gms"
    sleep 1
    echo -e "${ROBOT}[AI FIX]${NC} Installing MicroG components..."
    sleep 2
    echo -e "${ROBOT}[AI FIX]${NC} Enabling signature spoofing..."
    sleep 1
    echo -e "${ROBOT}[AI FIX]${NC} Configuring Google Services compatibility..."
    sleep 1
    echo -e "${CHECK} ${GREEN}Google Services compatibility enabled!${NC}"
    echo ""
}

demo_native_library() {
    echo -e "\n${GEAR} Native Library Fix Demo"
    echo "========================"
    echo "Simulating missing library fix..."

    echo -e "${YELLOW}[CRASH]${NC} UnsatisfiedLinkError: libexample.so not found"
    sleep 1
    echo -e "${ROBOT}[AI FIX]${NC} Analyzing missing library..."
    sleep 1
    echo -e "${ROBOT}[AI FIX]${NC} Creating compatibility shim..."
    sleep 2
    echo -e "${ROBOT}[AI FIX]${NC} Compiling native library stub..."
    sleep 1
    echo -e "${CHECK} ${GREEN}Native library compatibility resolved!${NC}"
    echo ""
}

demo_permissions() {
    echo -e "\n${GEAR} Permission Error Demo"
    echo "====================="
    echo "Simulating permission issue fix..."

    echo -e "${YELLOW}[ERROR]${NC} SecurityException: Permission denied"
    sleep 1
    echo -e "${ROBOT}[AI FIX]${NC} Analyzing required permissions..."
    sleep 1
    echo -e "${ROBOT}[AI FIX]${NC} Granting CAMERA permission..."
    sleep 1
    echo -e "${ROBOT}[AI FIX]${NC} Granting RECORD_AUDIO permission..."
    sleep 1
    echo -e "${CHECK} ${GREEN}Permissions granted successfully!${NC}"
    echo ""
}

demo_full_test() {
    echo -e "\n${ROCKET} Full Compatibility Test Suite"
    echo "=============================="

    apps=("WhatsApp" "Instagram" "Spotify" "Netflix" "Uber")

    for app in "${apps[@]}"; do
        echo -e "${BLUE}Testing $app...${NC}"
        sleep 1

        # Simulate random issue
        case $((RANDOM % 4)) in
            0) echo -e "  ${CHECK} ${GREEN}Working perfectly${NC}" ;;
            1) echo -e "  ${YELLOW}Minor permission fix applied${NC}" ;;
            2) echo -e "  ${YELLOW}Google Services patch applied${NC}" ;;
            3) echo -e "  ${YELLOW}Native library shim created${NC}" ;;
        esac
        sleep 1
    done

    echo -e "\n${CHECK} ${GREEN}All apps tested and working!${NC}"
    echo ""
}

airos_help() {
    echo -e "\n${ROBOT} AIROS Virtual Environment Help"
    echo "==============================="
    echo "Available commands:"
    echo "  airos-status    - Show system status"
    echo "  airos-start     - Start AI agent"
    echo "  airos-stop      - Stop AI agent"
    echo "  airos-monitor   - Monitor agent activity"
    echo "  airos-demo      - Run demo scenarios"
    echo "  airos-help      - Show this help"
    echo ""
    echo "Log files:"
    echo "  /var/log/airos/agent.log - Agent activity"
    echo ""
    echo "Configuration:"
    echo "  /etc/airos/airos.yml - Main configuration"
    echo ""
}

# Make commands available
alias airos-status='airos_status'
alias airos-start='airos_start'
alias airos-stop='airos_stop'
alias airos-monitor='airos_monitor'
alias airos-demo='airos_demo'
alias airos-help='airos_help'

# Export functions
export -f airos_status airos_start airos_stop airos_monitor airos_demo airos_help
export -f demo_whatsapp demo_google_services demo_native_library demo_permissions demo_full_test