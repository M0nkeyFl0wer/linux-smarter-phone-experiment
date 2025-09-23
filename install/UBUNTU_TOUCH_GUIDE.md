# Ubuntu Touch + AIROS Installation Guide for OnePlus 7 Pro

## Complete Step-by-Step Instructions with Commands and Troubleshooting

### Table of Contents
1. [Pre-Installation Checklist](#pre-installation-checklist)
2. [Phase 1: Computer Setup](#phase-1-computer-setup)
3. [Phase 2: Phone Preparation](#phase-2-phone-preparation)
4. [Phase 3: Ubuntu Touch Installation](#phase-3-ubuntu-touch-installation)
5. [Phase 4: AIROS Integration](#phase-4-airos-integration)
6. [Phase 5: App Setup & Testing](#phase-5-app-setup--testing)
7. [Troubleshooting Guide](#troubleshooting-guide)
8. [Recovery Options](#recovery-options)

---

## Pre-Installation Checklist

### ✅ Required Items
- [ ] OnePlus 7 Pro with >70% battery
- [ ] USB-C cable (preferably original)
- [ ] Computer with 10GB free space
- [ ] Stable internet connection
- [ ] 60-90 minutes of time
- [ ] Backup of important data completed

### ⚠️ Warnings
- **ALL DATA WILL BE ERASED** from the phone
- Process is reversible but takes effort
- Some features may not work initially
- You'll need to re-sign into all accounts

---

## Phase 1: Computer Setup

### For Windows Users

```powershell
# 1. Install Chocolatey (package manager)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 2. Install required tools
choco install adb fastboot wget git -y

# 3. Install Ubuntu Touch installer
# Download from: https://devices.ubuntu-touch.io/installer/
# Choose: ubports-installer_0.10.0_win.exe

# 4. Verify installation
adb --version
fastboot --version
```

### For Mac Users

```bash
# 1. Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install required tools
brew install android-platform-tools wget git

# 3. Install Ubuntu Touch installer
# Download from: https://devices.ubuntu-touch.io/installer/
# Choose: ubports-installer_0.10.0_mac.dmg

# 4. Verify installation
adb --version
fastboot --version
```

### For Linux Users (Ubuntu/Debian)

```bash
# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Install required tools
sudo apt install android-tools-adb android-tools-fastboot \
    wget git curl snap snapd -y

# 3. Install Ubuntu Touch installer
sudo snap install ubports-installer

# 4. Add user to necessary groups
sudo usermod -aG plugdev $USER
sudo usermod -aG dialout $USER

# 5. Logout and login for groups to take effect

# 6. Verify installation
adb --version
fastboot --version
ubports-installer --version
```

---

## Phase 2: Phone Preparation

### Step 1: Enable Developer Options

1. Go to **Settings** → **About phone**
2. Tap **Build number** 7 times
3. Enter your PIN/password if prompted
4. You'll see "You are now a developer!"

### Step 2: Enable USB Debugging & OEM Unlocking

1. Go to **Settings** → **System** → **Developer options**
2. Enable **OEM unlocking** (CRITICAL!)
3. Enable **USB debugging**
4. Enable **Advanced reboot** (optional but helpful)

### Step 3: Test ADB Connection

```bash
# Connect phone via USB
# Choose "File Transfer" mode on phone

# Test connection
adb devices

# You should see something like:
# a8f3d821  device

# If you see "unauthorized":
# - Check phone screen for authorization prompt
# - Tap "Always allow from this computer"
# - Tap OK
```

### Step 4: Backup Important Data

```bash
# Create full backup (optional but recommended)
adb backup -apk -shared -all -system -f oneplus7pro_backup.ab

# Pull important files
adb pull /sdcard/DCIM ./backup_photos
adb pull /sdcard/Download ./backup_downloads
adb pull /sdcard/Documents ./backup_documents
```

### Step 5: Unlock Bootloader

⚠️ **THIS WILL ERASE ALL DATA ON YOUR PHONE!**

```bash
# 1. Reboot to bootloader
adb reboot bootloader

# 2. Verify device is detected
fastboot devices

# 3. Check current lock status
fastboot oem device-info

# 4. If locked, unlock it:
fastboot oem unlock

# 5. Use volume keys to select "UNLOCK THE BOOTLOADER"
# Press power button to confirm

# 6. Phone will reboot and wipe all data
# This takes 5-10 minutes
```

---

## Phase 3: Ubuntu Touch Installation

### Step 1: Download Required Files

```bash
# Create work directory
mkdir ~/oneplus7pro_ubuntu
cd ~/oneplus7pro_ubuntu

# Files will be downloaded automatically by installer
# But good to have manual backups:

# Ubuntu Touch image (backup)
wget https://system-image.ubports.com/pool/ubports-cea3f0974cf8f5a0e1dc6f123c1b0b8a7c28ad7d65a3eb618bc7104b8c9e0e83.tar.xz

# Recovery image (backup)
wget https://github.com/ubports/android_device_oneplus_guacamole/releases/download/halium-11.0/recovery.img
```

### Step 2: Run UBports Installer

#### GUI Method (Recommended)

```bash
# 1. Launch installer
ubports-installer

# 2. Follow GUI steps:
# - Select device: OnePlus 7 Pro
# - Choose channel: Stable (recommended) or Development
# - Follow on-screen instructions
```

#### Command Line Method (Alternative)

```bash
# 1. Put phone in bootloader mode
adb reboot bootloader

# 2. Run installer in CLI mode
ubports-installer -d guacamole

# 3. Follow prompts
```

### Step 3: Installation Process

The installer will:
1. Download Ubuntu Touch image (~1GB)
2. Download device-specific files
3. Flash recovery partition
4. Boot to recovery
5. Push Ubuntu Touch files
6. Flash system image
7. Reboot to Ubuntu Touch

**This takes 15-20 minutes. DO NOT disconnect the cable!**

### Step 4: First Boot Setup

1. **Language Selection**: Choose your language
2. **WiFi Setup**: Connect to your network
3. **Account**: Create local account (no Ubuntu One needed)
4. **Security**: Set PIN/password
5. **Tutorial**: Complete or skip the tutorial

---

## Phase 4: AIROS Integration

### Step 1: Enable Developer Mode in Ubuntu Touch

1. Go to **Settings** → **About** → **Developer Mode**
2. Enable Developer Mode
3. Set a password for SSH access
4. Note the displayed IP address

### Step 2: Connect via SSH

```bash
# Method 1: WiFi (if on same network)
ssh phablet@<phone-ip-address>
# Password is what you just set

# Method 2: USB (more reliable)
# Enable SSH over USB in developer settings
adb forward tcp:2222 tcp:22
ssh phablet@localhost -p 2222
```

### Step 3: Install AIROS Components

```bash
# Once connected via SSH to the phone:

# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Install base dependencies
sudo apt install -y python3 python3-pip git curl wget \
    android-tools-adb sqlite3 build-essential

# 3. Download AIROS installer
cd ~
git clone https://github.com/airos/ubuntu-touch-airos.git
cd ubuntu-touch-airos

# 4. Run AIROS installer
chmod +x install-airos.sh
sudo ./install-airos.sh

# This script will:
# - Install Waydroid (Android compatibility layer)
# - Configure Waydroid with Android 11 image
# - Install MicroG services
# - Install Aurora Store
# - Set up AI compatibility service
# - Configure network bridges
# - Enable signature spoofing
```

### Step 4: Initialize Waydroid

```bash
# 1. Initialize Waydroid with GAPPS (will be replaced by MicroG)
sudo waydroid init -s GAPPS

# 2. Start Waydroid container
sudo systemctl start waydroid-container

# 3. Start Waydroid session
waydroid session start &

# 4. Show Waydroid UI
waydroid show-full-ui

# First boot takes 3-5 minutes
```

### Step 5: Install MicroG

```bash
# 1. Download MicroG components
cd /tmp
wget https://github.com/microg/GmsCore/releases/latest/download/GmsCore.apk
wget https://github.com/microg/GsfProxy/releases/latest/download/GsfProxy.apk
wget https://github.com/microg/FakeStore/releases/latest/download/FakeStore.apk
wget https://github.com/microg/UnifiedNlp/releases/latest/download/UnifiedNlp.apk

# 2. Install MicroG as system apps
sudo waydroid app install GmsCore.apk
sudo waydroid app install GsfProxy.apk
sudo waydroid app install FakeStore.apk
sudo waydroid app install UnifiedNlp.apk

# 3. Enable signature spoofing (required for MicroG)
cd ~/ubuntu-touch-airos
sudo ./enable-signature-spoofing.sh

# 4. Configure MicroG
waydroid app launch com.google.android.gms
# Enable all services in MicroG settings
```

### Step 6: Install Aurora Store

```bash
# 1. Download Aurora Store
wget https://f-droid.org/repo/com.aurora.store_37.apk

# 2. Install
sudo waydroid app install com.aurora.store_37.apk

# 3. Launch and configure
waydroid app launch com.aurora.store
# Choose "Anonymous" login
```

### Step 7: Set Up AI Compatibility Service

```bash
# 1. Install Python dependencies
pip3 install --user aiohttp psutil pyyaml watchdog dbus-python

# 2. Install AIROS AI service
cd ~/ubuntu-touch-airos
sudo cp airos-agent.service /etc/systemd/user/
sudo cp airos_linux_agent.py /opt/airos/

# 3. Configure service
sudo nano /etc/airos/config.yml
```

Add this configuration:

```yaml
version: 0.1.0
device: oneplus7pro
auth_token: $(uuidgen)  # Generate unique token

agent:
  port: 8080
  ws_port: 8081
  
waydroid:
  auto_start: true
  memory_limit: 3G
  cpu_cores: 6
  
compatibility:
  auto_fix: true
  monitor_crashes: true
  
microg:
  enabled: true
  gcm: true
  location: true
```

```bash
# 4. Start AI service
systemctl --user enable airos-agent
systemctl --user start airos-agent

# 5. Verify it's running
systemctl --user status airos-agent

# 6. Get auth token for remote access
grep auth_token /etc/airos/config.yml
```

---

## Phase 5: App Setup & Testing

### Step 1: Install Essential Apps

```bash
# Via Aurora Store (GUI):
# Open Aurora Store and search for:
# - WhatsApp
# - Instagram  
# - Spotify
# - Your banking apps
# - Firefox

# Via command line:
airos-cli install "WhatsApp"
airos-cli install "Instagram"
airos-cli install "Spotify"
```

### Step 2: Test App Compatibility

```bash
# Monitor for crashes
airos-cli monitor start

# Check compatibility database
airos-cli compat list

# Fix specific app if needed
airos-cli fix com.whatsapp
```

### Step 3: Connect from Computer

Create `test_connection.py` on your computer:

```python
#!/usr/bin/env python3
import requests
import json

# Replace with your phone's IP and token
PHONE_IP = "192.168.1.XXX"
AUTH_TOKEN = "your-token-from-config"

# Test connection
url = f"http://{PHONE_IP}:8080/api/system_info"
headers = {"Authorization": f"Bearer {AUTH_TOKEN}"}

response = requests.get(url, headers=headers)
if response.status_code == 200:
    info = response.json()
    print(f"Connected to {info['device']} running AIROS {info['version']}")
    print(f"Waydroid running: {info['waydroid_running']}")
    print(f"Installed apps: {info['installed_packages']}")
else:
    print(f"Connection failed: {response.status_code}")
```

Run it:
```bash
python3 test_connection.py
```

---

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue: "Waydroid won't start"

```bash
# Check if kernel modules are loaded
sudo modprobe binder_linux
sudo modprobe ashmem_linux

# Check Waydroid logs
sudo journalctl -u waydroid-container -f

# Reset Waydroid
sudo waydroid init -f
sudo systemctl restart waydroid-container
```

#### Issue: "Apps crash immediately"

```bash
# Check MicroG configuration
waydroid app launch com.google.android.gms

# Ensure all MicroG services are enabled
# Especially: Device registration, Cloud Messaging, Location

# Re-enable signature spoofing
cd ~/ubuntu-touch-airos
sudo ./enable-signature-spoofing.sh

# Clear app data and retry
waydroid app clear com.example.app
```

#### Issue: "No network in Waydroid"

```bash
# Check network bridge
ip addr show waydroid0

# Restart networking
sudo systemctl restart systemd-networkd
sudo systemctl restart waydroid-container

# Configure DNS
echo "nameserver 8.8.8.8" | sudo tee /var/lib/waydroid/overlay/system/etc/resolv.conf
```

#### Issue: "Banking app detects root"

```bash
# Hide root from app
airos-cli hide-root com.banking.app

# Use MicroG's SafetyNet implementation
airos-cli safetynet enable

# If still detected, patch the APK
airos-cli patch com.banking.app --remove-root-check
```

#### Issue: "Phone gets hot / battery drain"

```bash
# Limit Waydroid CPU usage
sudo waydroid config set cpu_limit=50

# Disable unnecessary services
airos-cli optimize battery

# Check what's using resources
airos-cli monitor resources
```

---

## Recovery Options

### Option 1: Restore Ubuntu Touch

```bash
# Boot to recovery (Power + Volume Down)
# Or via ADB:
adb reboot recovery

# In recovery, choose "Factory Reset"
```

### Option 2: Return to Stock Android

```bash
# 1. Download OnePlus 7 Pro stock ROM
# https://www.oneplus.com/support/softwareupgrade/details?code=PM1574156267635

# 2. Extract and flash with fastboot
fastboot flash boot boot.img
fastboot flash dtbo dtbo.img
fastboot flash system system.img
fastboot flash vendor vendor.img
fastboot flash vbmeta vbmeta.img
fastboot -w
fastboot reboot
```

### Option 3: Use MSM Tool (Complete Recovery)

```bash
# 1. Download MSM Tool for OnePlus 7 Pro
# Search: "OnePlus 7 Pro MSM Tool XDA"

# 2. Install Qualcomm drivers (Windows)

# 3. Put phone in EDL mode:
# - Turn off phone
# - Hold Volume Up + Volume Down
# - Connect USB cable

# 4. Run MSM Tool and click Start
# This completely restores factory firmware
```

---

## Performance Optimization

### After everything is working:

```bash
# 1. Enable 90Hz display (if not already)
gsettings set com.ubuntu.touch.system display-refresh-rate 90

# 2. Optimize app launching
airos-cli optimize app-launch

# 3. Enable zram compression
sudo apt install zram-config
sudo systemctl enable zram-config

# 4. Set CPU governor for performance
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 5. Configure Waydroid for optimal performance
sudo waydroid config set renderer gpu
sudo waydroid config set hwcodec true
sudo waydroid config set memory 4096
```

---

## Daily Usage Tips

### Battery Saving Mode
```bash
airos-cli mode battery-saver
```

### Performance Mode (gaming/heavy apps)
```bash
airos-cli mode performance
```

### Quick App Fixes
```bash
# If an app stops working
airos-cli fix <package-name> --aggressive
```

### Update System
```bash
# Ubuntu Touch updates
sudo apt update && sudo apt upgrade

# AIROS updates
airos-cli update

# Waydroid image updates
sudo waydroid upgrade
```

---

## Congratulations! 🎉

You now have a fully functional Ubuntu Touch phone with:
- ✅ Native Linux environment
- ✅ Android app compatibility via Waydroid
- ✅ Google Services replacement (MicroG)
- ✅ Anonymous Play Store access (Aurora)
- ✅ AI-powered app compatibility fixing
- ✅ Remote control capability for AI experiments

## Next Steps:

1. Join the Ubuntu Touch community: https://t.me/ubports
2. Explore Linux phone apps: https://open-store.io
3. Share your app compatibility fixes: `airos-cli share-fixes`
4. Start experimenting with AI control!

## Support Resources:

- Ubuntu Touch Forums: https://forums.ubports.com
- OnePlus 7 Pro specific: https://t.me/ut_oneplus6
- AIROS Issues: https://github.com/airos/ubuntu-touch-airos/issues