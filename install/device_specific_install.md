# AIROS Installation Guide - Pixel 4a 5G & OnePlus 7 Pro

## Device Comparison

| Feature | Pixel 4a 5G (bramble) | OnePlus 7 Pro (guacamole) |
|---------|----------------------|---------------------------|
| **Linux Support** | ⭐⭐⭐ Good | ⭐⭐⭐⭐⭐ Excellent |
| **PostmarketOS** | ✅ Supported | ✅ Well Supported |
| **Ubuntu Touch** | ✅ Supported | ✅ Well Supported |
| **Droidian** | ✅ Supported | ✅ Supported |
| **Hardware Accel** | Partial | Full |
| **Camera** | Basic | Good |
| **Recommendation** | Good for testing | **Best choice!** |

## 🎯 Quick Recommendation

**Start with the OnePlus 7 Pro** - It has exceptional Linux phone support with nearly full hardware functionality. The pop-up camera even works! Keep the Pixel 4a 5G for the Android variant or as a backup.

---

## OnePlus 7 Pro Installation (RECOMMENDED)

The OnePlus 7 Pro is one of the best supported mainstream phones for Linux. You can choose between three approaches:

### Option A: PostmarketOS with AIROS (Most Stable)

#### Prerequisites
```bash
# On your computer (Linux/Mac/WSL2)
# Install required tools
sudo apt update
sudo apt install android-tools-adb android-tools-fastboot
pip3 install pmbootstrap
```

#### Step 1: Unlock Bootloader
```bash
# 1. Enable Developer Options on phone
# Settings > About > Tap "Build number" 7 times

# 2. Enable OEM Unlocking & USB Debugging
# Settings > Developer Options > OEM Unlocking (enable)
# Settings > Developer Options > USB Debugging (enable)

# 3. Boot to bootloader
adb reboot bootloader

# 4. Unlock bootloader (WILL WIPE DATA!)
fastboot oem unlock

# Phone will reboot and wipe
```

#### Step 2: Install PostmarketOS
```bash
# Initialize pmbootstrap
pmbootstrap init

# When prompted, select:
# - Channel: edge (for latest features)
# - Vendor: oneplus
# - Device: oneplus-guacamole (OnePlus 7 Pro)
# - Username: user (or your choice)
# - UI: phosh (recommended) or plasma-mobile
# - Extra options: 
#   [x] Enable Waydroid (Android app support)
#   [x] Enable SSH daemon

# Build the image
pmbootstrap build

# Create installation image
pmbootstrap install

# Flash to device
pmbootstrap flasher flash_kernel
pmbootstrap flasher flash_rootfs
```

#### Step 3: Install AIROS Components
```bash
# Boot the phone with PostmarketOS
# Connect via SSH (password is what you set during init)
ssh user@172.16.42.1

# Download and run AIROS installer
wget https://raw.githubusercontent.com/airos/main/install-airos-linux.sh
chmod +x install-airos-linux.sh
sudo ./install-airos-linux.sh

# The installer will:
# - Set up Waydroid with Android 13
# - Install MicroG for Google Services
# - Install Aurora Store
# - Configure AI agent service
# - Set up app compatibility fixer
```

### Option B: Ubuntu Touch with AIROS (Easiest)

Ubuntu Touch has excellent OnePlus 7 Pro support with a polished interface.

#### Step 1: Install Ubuntu Touch Installer
```bash
# Download UBports installer for your OS
# https://ubuntu-touch.io/get-ubuntu-touch

# Or use command line (Linux)
sudo snap install ubports-installer
```

#### Step 2: Flash Ubuntu Touch
```bash
# 1. Connect phone in bootloader mode
adb reboot bootloader

# 2. Run installer
ubports-installer

# 3. Select OnePlus 7 Pro and follow prompts
# Takes about 10-15 minutes
```

#### Step 3: Install AIROS Layer
```bash
# Enable developer mode in Ubuntu Touch
# Settings > About > Developer Mode

# SSH into device
ssh phablet@<device-ip>

# Install AIROS
wget https://raw.githubusercontent.com/airos/main/install-airos-ubuntu-touch.sh
chmod +x install-airos-ubuntu-touch.sh
sudo ./install-airos-ubuntu-touch.sh
```

### Option C: Droidian (Debian-based, Newest)

Droidian offers the most desktop-like Linux experience with excellent app compatibility.

```bash
# Download Droidian image
wget https://github.com/droidian-images/rootfs-api28gsi-all/releases/download/droidian/droidian-rootfs-api28gsi-arm64.zip

# Flash using fastboot
fastboot flash system droidian-rootfs-api28gsi-arm64.img
fastboot -w
fastboot reboot

# After boot, install AIROS
sudo apt update
sudo apt install wget
wget https://raw.githubusercontent.com/airos/main/install-airos-droidian.sh
sudo bash install-airos-droidian.sh
```

---

## Pixel 4a 5G Installation

The Pixel 4a 5G has good but not perfect Linux support. Some features like camera may not work fully.

### Option A: PostmarketOS (Recommended)

```bash
# Initialize pmbootstrap
pmbootstrap init

# Select:
# - Vendor: google
# - Device: google-bramble (Pixel 4a 5G)
# - UI: phosh
# - Extra: Waydroid support

# Build and install
pmbootstrap build
pmbootstrap install

# Flash to device
pmbootstrap flasher flash_kernel
pmbootstrap flasher flash_rootfs

# Install AIROS after boot
ssh user@172.16.42.1
wget https://raw.githubusercontent.com/airos/main/install-airos-linux.sh
sudo bash install-airos-linux.sh
```

### Option B: CalyxOS/GrapheneOS with AIROS Layer

For better Android app compatibility, you can use a privacy-focused Android ROM with AIROS additions:

```bash
# 1. Install CalyxOS or GrapheneOS
# Follow their official installers:
# CalyxOS: https://calyxos.org/install/
# GrapheneOS: https://grapheneos.org/install/

# 2. After installation, enable root access
# (CalyxOS has built-in root, GrapheneOS needs manual setup)

# 3. Install AIROS Android components
adb push airos-android-agent.apk /data/local/tmp/
adb shell su -c "pm install -r /data/local/tmp/airos-android-agent.apk"

# 4. Start AI agent
adb shell su -c "am start-service com.airos.agent/.AIAgentService"
```

---

## Post-Installation Setup

### 1. First Boot Configuration

```bash
# Connect to device (via SSH or directly)
# For PostmarketOS/Droidian over USB:
ssh user@172.16.42.1

# For Ubuntu Touch:
ssh phablet@<device-ip>

# Verify AIROS is running
sudo systemctl status airos-agent

# Get authentication token
cat /etc/airos/config.yml | grep auth_token
```

### 2. Connect from Your Computer

```python
# Install AIROS client on your computer
pip install airos-client

# Connect to phone
from airos_client import AIROSClient

# Use the device's IP address
client = AIROSClient("192.168.1.XXX", "your-auth-token")

# Test connection
info = client.get_system_info()
print(f"Connected to {info.device}")
```

### 3. Install Your First Android App

```bash
# Using Aurora Store (GUI)
# 1. Open Aurora Store on phone
# 2. Search for any app
# 3. Install - AIROS will auto-fix compatibility issues

# Using command line
airos-cli install "WhatsApp"
airos-cli install "Instagram"
airos-cli install "Spotify"

# Check compatibility fixes applied
airos-cli fixes list
```

### 4. Enable AI Auto-Fixing

```bash
# Start continuous monitoring
airos-cli monitor start

# Enable aggressive fixing
airos-cli config set auto_fix=aggressive

# Watch the magic happen
tail -f /var/log/airos/fixes.log
```

---

## Performance Optimization

### For OnePlus 7 Pro

```bash
# Enable performance mode
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Optimize Waydroid for Snapdragon 855
sudo waydroid-config set cpu_cores=8
sudo waydroid-config set memory=4096
sudo waydroid-config set gpu_accel=true

# Enable 90Hz display (if supported by Linux distro)
echo 90 | sudo tee /sys/class/display/panel0/fps
```

### For Pixel 4a 5G

```bash
# Balanced performance (Snapdragon 765G)
echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Configure Waydroid
sudo waydroid-config set cpu_cores=6
sudo waydroid-config set memory=3072
```

---

## Troubleshooting

### Common Issues

#### "Waydroid won't start"
```bash
# Check kernel support
sudo modprobe binder_linux
sudo modprobe ashmem_linux

# If missing, you need a kernel with Android support
# PostmarketOS edge channel usually has this
```

#### "Apps crash immediately"
```bash
# Check MicroG status
airos-cli microg status

# Re-enable signature spoofing
airos-cli microg fix-spoofing

# Force compatibility re-scan
airos-cli fix --force --all
```

#### "Poor battery life"
```bash
# Reduce Waydroid CPU usage
sudo waydroid-config set cpu_limit=50

# Disable unnecessary services
airos-cli optimize battery
```

#### "No mobile data"
```bash
# Configure APN settings
sudo nmcli connection edit type gsm
# Follow prompts for your carrier

# Restart modem
sudo systemctl restart ModemManager
```

---

## Daily Driver Viability

### OnePlus 7 Pro - Rating: 8/10
✅ **Working:**
- Calls, SMS, Mobile Data
- WiFi, Bluetooth
- Most Android apps via Waydroid
- Camera (basic functionality)
- 90Hz display (with Droidian)
- GPS
- Fingerprint (depends on distro)

❌ **Not Working:**
- Some camera features (portrait mode, etc.)
- Wireless charging (N/A on this model)
- Some proprietary apps may need fixes
- Netflix/DRM content (fixable)

### Pixel 4a 5G - Rating: 6/10
✅ **Working:**
- Basic phone functions
- WiFi
- Most Android apps
- Basic camera

❌ **Not Working/Limited:**
- Advanced camera features
- 5G (usually only 4G works)
- Fingerprint sensor (distro dependent)
- Some Bluetooth profiles

---

## Advanced: Dual-Boot Setup

Want to keep Android for daily use but experiment with AIROS Linux?

### For OnePlus 7 Pro (using TWRP)

```bash
# 1. Install TWRP recovery
fastboot boot twrp-3.7.0-guacamole.img

# 2. In TWRP, create partitions
# - Resize system partition
# - Create new partition for Linux

# 3. Install Android ROM to slot A
# 4. Install PostmarketOS to slot B

# 5. Use TWRP to switch between ROMs
```

### Quick Switch Script
```bash
#!/bin/bash
# switch-os.sh
CURRENT=$(fastboot getvar current-slot 2>&1 | grep current-slot | cut -d' ' -f2)
if [ "$CURRENT" = "a" ]; then
    fastboot --set-active=b
    echo "Switched to Linux (slot B)"
else
    fastboot --set-active=a
    echo "Switched to Android (slot A)"
fi
fastboot reboot
```

---

## Recommended First Steps

1. **Start with OnePlus 7 Pro + PostmarketOS**
   - Most stable and feature-complete
   - Best hardware support
   - Great performance

2. **Install these essential apps first:**
   ```bash
   airos-cli install "F-Droid"      # Open source app store
   airos-cli install "Firefox"      # Browser
   airos-cli install "Signal"       # Messaging
   airos-cli install "Element"      # Matrix chat
   airos-cli install "Organic Maps" # Offline navigation
   ```

3. **Join the community:**
   - PostmarketOS Matrix: #postmarketos:postmarketos.org
   - Ubuntu Touch Telegram: @ubports
   - AIROS Discord: discord.gg/airos (fictional)

4. **Contribute fixes:**
   ```bash
   # When you fix an app, share it!
   airos-cli fix export com.example.app
   airos-cli fix submit
   ```

---

## Safety Note

**Before starting:**
- ✅ Backup all data from the phone
- ✅ Ensure battery is >70% charged
- ✅ Have a USB cable ready
- ✅ Download all files before starting
- ✅ Have a backup phone available

**Recovery Options:**
- Both phones can be restored to stock Android
- OnePlus: MSM Download Tool
- Pixel: Google's Flash Tool

The OnePlus 7 Pro is particularly great because it's powerful, has a beautiful screen, and the Linux community has put serious effort into supporting it. You'll be surprised how daily-driveable it is with AIROS!