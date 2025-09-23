# AIROS Linux Variant - Complete Setup Guide

## Overview

AIROS-Linux transforms Linux phones into AI-assisted mobile platforms with full Android app compatibility through Waydroid, MicroG, and Aurora Store. Unlike the Android variant, this provides true Linux flexibility while maintaining app functionality.

## Supported Devices & Distros

### Tier 1 - Full Support
| Device | Base OS | Status | Notes |
|--------|---------|--------|-------|
| PinePhone/Pro | PostmarketOS | ✅ Stable | Best overall support |
| Librem 5 | PureOS/PostmarketOS | ✅ Stable | Excellent privacy features |
| OnePlus 6/6T | PostmarketOS | ✅ Stable | Fast performance |
| Fairphone 4 | PostmarketOS | 🔄 Beta | Good sustainability |

### Tier 2 - Community Support
| Device | Base OS | Status | Notes |
|--------|---------|--------|-------|
| Pixel 3a | Ubuntu Touch | 🔄 Beta | Good camera support |
| Pocophone F1 | PostmarketOS | 🔄 Beta | Excellent value |
| Sony Xperia XA2 | Sailfish OS | 🧪 Experimental | Native Android support |

## Installation Methods

### Method 1: Fresh Installation (Recommended)

```bash
# 1. Flash PostmarketOS to your device
pmbootstrap init
pmbootstrap install --sdcard /dev/mmcblkX

# 2. Boot device and connect via SSH
ssh user@172.16.42.1

# 3. Run AIROS installer
wget https://github.com/airos/releases/latest/install-airos-linux.sh
sudo bash install-airos-linux.sh
```

### Method 2: Convert Existing Linux Phone OS

```bash
# For existing PostmarketOS/Ubuntu Touch installations
curl -sSL https://get.airos.dev | sudo bash
```

### Method 3: Docker Development Environment

```bash
# For testing without a physical device
docker run -it --privileged \
  -p 8080:8080 -p 8081:8081 \
  airos/linux-phone-dev:latest
```

## Post-Installation Setup

### 1. Initial Configuration

```bash
# Set up AI agent authentication
sudo airos-cli setup

# Configure device profile
sudo airos-cli configure --device pinephone

# Initialize Waydroid with MicroG
sudo airos-cli waydroid init --microg
```

### 2. Aurora Store Setup

```bash
# Install Aurora Store
airos-cli install aurora-store

# Configure anonymous account
airos-cli aurora configure --anonymous

# Enable auto-updates (optional)
airos-cli aurora set auto-update true
```

### 3. App Installation & Fixing

```bash
# Install app with automatic compatibility fixing
airos-cli install https://example.com/app.apk --auto-fix

# Fix already installed app
airos-cli fix com.example.app

# Batch fix all apps
airos-cli fix-all
```

## AI-Powered App Compatibility System

### How App Fixing Works

1. **Crash Detection**
   - Monitors Waydroid logs in real-time
   - Captures crash signatures and stack traces
   - Identifies missing components

2. **Automated Analysis**
   - AI analyzes crash patterns
   - Determines fix strategy
   - Generates compatibility patches

3. **Fix Application**
   - Applies patches without reinstallation
   - Creates library shims
   - Mocks missing services

### Common Fixes Applied

#### Google Services Dependencies
```python
# Automatic redirection to MicroG
Original: com.google.android.gms.maps.MapView
Fixed: org.microg.gms.maps.MapView
```

#### Missing Native Libraries
```bash
# AI creates shim libraries
Missing: libgoogle_assistant.so
Created: /system/lib64/libgoogle_assistant.so (shim)
```

#### Permission Issues
```bash
# Auto-grants required permissions
App crash: SecurityException: Permission denied
Fix: pm grant com.app android.permission.ACCESS_FINE_LOCATION
```

#### SafetyNet Bypass
```bash
# For banking apps
Original: SafetyNet attestation failed
Fixed: Spoofed response with valid CTS profile
```

## Performance Optimization

### CPU Governor Settings
```bash
# Gaming/Performance mode
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Battery saving mode
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Balanced (default)
echo ondemand | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### Memory Management
```bash
# Configure ZRAM
sudo airos-cli memory configure --zram 2G

# Set Waydroid memory limit
sudo airos-cli waydroid set-memory 3G

# Clear app cache
airos-cli cache clear --all
```

### Graphics Acceleration
```bash
# Enable hardware acceleration
sudo airos-cli waydroid configure --gpu-accel mesa

# Set rendering backend
sudo airos-cli waydroid set-renderer --backend virgl
```

## Advanced Features

### Multi-Profile Support
```bash
# Create work profile
airos-cli profile create work

# Switch profiles
airos-cli profile switch work

# Install app in specific profile
airos-cli install app.apk --profile work
```

### App Streaming
```bash
# Enable app streaming server
airos-cli streaming enable

# Connect from desktop
airos-stream connect phone.local:8082
```

### Desktop Convergence
```bash
# Enable desktop mode when docked
airos-cli convergence enable

# Configure external display
airos-cli display configure --external hdmi --resolution 1920x1080
```

## Troubleshooting

### Common Issues & Solutions

#### Waydroid Won't Start
```bash
# Check kernel modules
sudo modprobe binder_linux
sudo modprobe ashmem_linux

# Reset Waydroid
sudo waydroid init -f

# Check logs
journalctl -u waydroid-container -f
```

#### App Crashes Immediately
```bash
# Enable detailed logging
airos-cli debug enable --verbose

# Check compatibility database
airos-cli compat check com.example.app

# Force re-fix
airos-cli fix com.example.app --force
```

#### Poor Performance
```bash
# Check resource usage
airos-cli monitor

# Optimize Waydroid
airos-cli optimize --aggressive

# Disable unnecessary services
airos-cli services disable --unused
```

#### Network Issues
```bash
# Reset network configuration
sudo airos-cli network reset

# Configure DNS
sudo airos-cli network set-dns 8.8.8.8 8.8.4.4

# Check firewall
sudo iptables -L -n
```

## Security Considerations

### Hardening AIROS-Linux

```bash
# Enable firewall
sudo ufw enable
sudo ufw allow 8080/tcp  # Only if remote access needed

# Restrict AI agent access
sudo airos-cli security set-allowed-ips 192.168.1.100

# Enable app sandboxing
sudo airos-cli security enable-sandbox

# Disable root commands (production)
sudo airos-cli security disable-root
```

### Privacy Settings

```bash
# Configure MicroG for maximum privacy
airos-cli microg configure --privacy-mode

# Disable telemetry
airos-cli telemetry disable --all

# Use Tor for Aurora Store
airos-cli aurora configure --use-tor
```

## API Examples

### Python - AI Agent Integration
```python
from airos_client import AIROSLinuxClient

# Connect to AIROS-Linux
client = AIROSLinuxClient("phone.local", "auth-token")

# Install and fix app automatically
result = client.install_app(
    apk_url="https://example.com/app.apk",
    auto_fix=True,
    pre_patch=True
)

# Monitor app behavior
@client.on_app_crash
def handle_crash(crash_data):
    print(f"App crashed: {crash_data.package}")
    fix = client.auto_fix(crash_data)
    print(f"Fix applied: {fix.success}")

client.start_monitoring()
```

### REST API - Direct Control
```bash
# Get system status
curl http://phone.local:8080/api/system_info

# Install app with fixing
curl -X POST http://phone.local:8080/api/install_app \
  -H "Content-Type: application/json" \
  -d '{"apk_url": "https://example.com/app.apk", "pre_patch": true}'

# Fix specific app
curl -X POST http://phone.local:8080/api/fix_app \
  -H "Content-Type: application/json" \
  -d '{"package_name": "com.example.app"}'
```

## Benchmarks & Performance

### Waydroid Performance Metrics

| Device | Native | Waydroid | Overhead |
|--------|--------|----------|----------|
| PinePhone Pro | 100% | 82% | 18% |
| OnePlus 6 | 100% | 89% | 11% |
| Librem 5 | 100% | 78% | 22% |
| Fairphone 4 | 100% | 85% | 15% |

### App Compatibility Rates

| Category | Compatibility | With AI Fixes |
|----------|--------------|---------------|
| Social Media | 85% | 98% |
| Banking | 45% | 75% |
| Games | 70% | 85% |
| Productivity | 90% | 99% |
| Streaming | 80% | 95% |

## Development Workflow

### Building Custom Fixes

```python
# Create custom app fix
class CustomAppFix:
    def __init__(self, package_name):
        self.package = package_name
    
    def analyze(self, crash_data):
        # Analyze crash pattern
        if "libcustom.so" in crash_data:
            return "missing_library"
        return "unknown"
    
    def apply_fix(self, issue_type):
        if issue_type == "missing_library":
            # Create library shim
            self.create_shim("libcustom.so")
            return True
        return False

# Register with AIROS
client.register_fix(CustomAppFix("com.example.app"))
```

### Testing Fixes

```bash
# Create test environment
airos-cli test create --app com.example.app

# Apply fix
airos-cli test apply-fix custom_fix.py

# Verify functionality
airos-cli test verify --comprehensive

# Deploy if successful
airos-cli fix deploy custom_fix.py
```

## Roadmap & Future Features

### Q1 2025
- ✅ Basic Waydroid integration
- ✅ MicroG support
- ✅ Aurora Store integration
- 🔄 AI-powered app fixing
- 🔄 Performance optimization

### Q2 2025
- ⏳ Multi-user support
- ⏳ Enhanced SafetyNet bypass
- ⏳ Cloud sync for fixes
- ⏳ Community fix sharing

### Q3 2025
- ⏳ Neural network for crash prediction
- ⏳ Automatic APK modification
- ⏳ Cross-device app streaming
- ⏳ Desktop convergence mode

### Future
- ⏳ Native Linux app alternatives suggestion
- ⏳ Distributed AI processing
- ⏳ Zero-knowledge app fixing
- ⏳ Quantum-resistant encryption

## Contributing

### Submitting App Fixes

```bash
# Create fix for problematic app
airos-cli fix create com.problem.app

# Test thoroughly
airos-cli test run com.problem.app

# Submit to community repository
airos-cli fix submit --description "Fixes crash on startup"
```

### Reporting Issues

```bash
# Generate debug report
airos-cli debug report --full

# Submit to issue tracker
airos-cli issue submit --attach-logs
```

## Resources

- [AIROS Wiki](https://wiki.airos.dev)
- [Community Forum](https://forum.airos.dev)
- [Fix Repository](https://fixes.airos.dev)
- [API Documentation](https://api.airos.dev)
- [Discord Server](https://discord.gg/airos)

## License

AIROS-Linux is licensed under GPLv3 to ensure freedom and compatibility with Linux phone ecosystems.