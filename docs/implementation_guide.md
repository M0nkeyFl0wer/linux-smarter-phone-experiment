# AIROS Implementation Guide

## Step-by-Step Instructions for Building and Deploying AIROS

### Prerequisites Setup

#### 1. Development Environment
```bash
# Ubuntu 20.04 or later recommended
sudo apt update
sudo apt install -y \
    git-core gnupg flex bison build-essential \
    zip curl zlib1g-dev gcc-multilib g++-multilib \
    libc6-dev-i386 lib32ncurses5-dev x11proto-core-dev \
    libx11-dev lib32z1-dev libgl1-mesa-dev \
    libxml2-utils xsltproc unzip fontconfig \
    python3 python3-pip openjdk-11-jdk
```

#### 2. Install Repo Tool
```bash
mkdir ~/bin
PATH=~/bin:$PATH
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
```

#### 3. Setup Git Configuration
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Phase 1: Source Code Setup

#### 1. Create Working Directory
```bash
mkdir ~/airos
cd ~/airos
```

#### 2. Initialize LineageOS Base (for Pixel 4a example)
```bash
# Using LineageOS as base for easier device support
repo init -u https://github.com/LineageOS/android.git -b lineage-20.0 --depth=1
```

#### 3. Create Local Manifests for AIROS
```bash
mkdir -p .repo/local_manifests
cat > .repo/local_manifests/airos.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <!-- AIROS specific repositories -->
  <project name="airos/agent" path="packages/apps/AIROSAgent" remote="github" revision="main"/>
  <project name="airos/framework-mods" path="vendor/airos" remote="github" revision="main"/>
  
  <!-- Device specific (Pixel 4a - sunfish) -->
  <project name="LineageOS/android_device_google_sunfish" path="device/google/sunfish" remote="github" revision="lineage-20.0"/>
  <project name="LineageOS/android_kernel_google_sunfish" path="kernel/google/sunfish" remote="github" revision="lineage-20.0"/>
  <project name="TheMuppets/proprietary_vendor_google" path="vendor/google" remote="github" revision="lineage-20.0"/>
</manifest>
EOF
```

#### 4. Sync Source Code
```bash
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle
```

### Phase 2: AIROS Components Integration

#### 1. Create AIROS Directory Structure
```bash
cd ~/airos
mkdir -p packages/apps/AIROSAgent/{src,res,jni,scripts}
mkdir -p vendor/airos/{config,patches,prebuilt}
```

#### 2. Copy AIROS Source Files
```bash
# Copy the Java service code
cp AIAgentService.java packages/apps/AIROSAgent/src/com/airos/agent/

# Copy manifest
cp AndroidManifest.xml packages/apps/AIROSAgent/

# Copy build configuration
cp Android.mk packages/apps/AIROSAgent/
```

#### 3. Create Init RC File
```bash
cat > packages/apps/AIROSAgent/init/airos_agent.rc << 'EOF'
# AIROS Agent Service init configuration

on boot
    # Set permissions for AI agent
    chmod 0755 /system/bin/airos-cli
    chmod 0755 /system/bin/airos-restore
    
    # Create working directories
    mkdir /data/airos 0777 system system
    mkdir /data/airos/snapshots 0777 system system
    mkdir /data/airos/logs 0777 system system
    
    # Set system properties
    setprop airos.version 0.1.0-alpha
    setprop airos.debug.level verbose
    setprop airos.agent.enabled true

service airos_agent /system/bin/app_process /system/bin --nice-name=airos_agent com.airos.agent.AIAgentService
    class core
    user system
    group system inet net_admin net_raw
    capabilities NET_ADMIN NET_RAW SYS_MODULE SYS_ADMIN
    disabled

on property:airos.agent.enabled=true
    start airos_agent

on property:airos.agent.enabled=false
    stop airos_agent
EOF
```

#### 4. Create System Properties File
```bash
cat > packages/apps/AIROSAgent/airos.prop << 'EOF'
# AIROS System Properties
airos.version=0.1.0-alpha
airos.debug.enabled=1
airos.debug.level=verbose
airos.agent.enabled=true
airos.agent.port=8080
airos.agent.ws_port=8081
airos.security.weakened=true
airos.rollback.enabled=true
airos.injection.enabled=true

# Development flags
ro.adb.secure=0
ro.debuggable=1
persist.service.adb.enable=1
persist.service.debuggable=1
EOF
```

### Phase 3: Framework Modifications

#### 1. Create Framework Patches
```bash
cat > vendor/airos/patches/0001-weaken-security.patch << 'EOF'
--- a/frameworks/base/services/core/java/com/android/server/pm/PackageManagerService.java
+++ b/frameworks/base/services/core/java/com/android/server/pm/PackageManagerService.java
@@ -1234,6 +1234,11 @@
     private void enforceSystemOrRoot(String message) {
+        // AIROS: Allow AI agent to have system privileges
+        if (isCallerAIAgent()) {
+            return;
+        }
         final int uid = Binder.getCallingUid();
         if (uid != Process.SYSTEM_UID && uid != Process.ROOT_UID) {
             throw new SecurityException(message);
         }
     }
+    
+    private boolean isCallerAIAgent() {
+        return "com.airos.agent".equals(getNameForUid(Binder.getCallingUid()));
+    }
EOF
```

#### 2. Apply Patches
```bash
cd frameworks/base
git apply ../../vendor/airos/patches/0001-weaken-security.patch
cd ../..
```

### Phase 4: Build Configuration

#### 1. Create Device Configuration
```bash
cat > device/google/sunfish/airos.mk << 'EOF'
# AIROS specific configuration for Pixel 4a

# Inherit LineageOS base
$(call inherit-product, device/google/sunfish/lineage_sunfish.mk)

# AIROS packages
PRODUCT_PACKAGES += \
    AIROSAgent \
    airos-cli \
    airos-restore \
    libairos_native \
    libairos_injection \
    libairos_monitor

# AIROS properties
PRODUCT_PROPERTY_OVERRIDES += \
    airos.version=0.1.0-alpha \
    airos.device=sunfish

# Copy init files
PRODUCT_COPY_FILES += \
    packages/apps/AIROSAgent/init/airos_agent.rc:$(TARGET_COPY_OUT_SYSTEM)/etc/init/airos_agent.rc

# SELinux permissive mode for development
PRODUCT_PROPERTY_OVERRIDES += \
    ro.build.selinux=0

PRODUCT_NAME := airos_sunfish
PRODUCT_DEVICE := sunfish
PRODUCT_BRAND := AIROS
PRODUCT_MODEL := AIROS Pixel 4a
PRODUCT_MANUFACTURER := Google

# Build fingerprint
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="sunfish-user 13 TQ3A.230901.001 10750268 release-keys"
EOF
```

#### 2. Add to Lunch Menu
```bash
cat >> vendor/airos/vendorsetup.sh << 'EOF'
add_lunch_combo airos_sunfish-userdebug
add_lunch_combo airos_sunfish-eng
EOF
```

### Phase 5: Building the ROM

#### 1. Setup Build Environment
```bash
cd ~/airos
source build/envsetup.sh
```

#### 2. Choose Build Target
```bash
lunch airos_sunfish-userdebug
```

#### 3. Build the ROM
```bash
# Full build (takes 2-4 hours)
make -j$(nproc --all) otapackage

# Or faster incremental build for testing
make -j$(nproc --all) systemimage
```

#### 4. Output Location
```bash
# Full OTA package
ls -la out/target/product/sunfish/airos_sunfish-*.zip

# Individual images
ls -la out/target/product/sunfish/*.img
```

### Phase 6: Device Preparation

#### 1. Unlock Bootloader
```bash
# Enable Developer Options and OEM Unlocking on device
adb reboot bootloader
fastboot flashing unlock
# Confirm on device screen
```

#### 2. Install Custom Recovery (Optional but Recommended)
```bash
# Download TWRP for sunfish
wget https://dl.twrp.me/sunfish/twrp-3.7.0_9-0-sunfish.img

# Flash TWRP
fastboot boot twrp-3.7.0_9-0-sunfish.img
# In TWRP, go to Advanced > Flash Current TWRP
```

### Phase 7: Installation

#### Method A: Using Custom Recovery
```bash
# 1. Copy ROM to device
adb push out/target/product/sunfish/airos_sunfish-*.zip /sdcard/

# 2. Boot to recovery
adb reboot recovery

# 3. In TWRP:
#    - Wipe > Format Data
#    - Install > Select airos_sunfish-*.zip
#    - Swipe to confirm flash
#    - Reboot System
```

#### Method B: Using Fastboot
```bash
# Extract images from OTA
cd out/target/product/sunfish/
unzip airos_sunfish-*.zip -d airos_images/

# Flash all partitions
fastboot flash boot boot.img
fastboot flash dtbo dtbo.img
fastboot flash system system.img
fastboot flash system_ext system_ext.img
fastboot flash product product.img
fastboot flash vendor vendor.img
fastboot flash vbmeta vbmeta.img

# Wipe userdata (optional, for clean install)
fastboot -w

# Reboot
fastboot reboot
```

### Phase 8: Post-Installation Setup

#### 1. Initial Boot
- First boot takes 5-10 minutes
- Device will optimize apps
- May reboot once automatically

#### 2. Enable AI Agent Service
```bash
# Check if device booted successfully
adb devices

# Verify AIROS is running
adb shell getprop airos.version

# Check AI Agent service status
adb shell ps | grep airos

# View AI Agent logs
adb logcat -s AIROS:V
```

#### 3. Get Authentication Token
```bash
# Get the initial auth token
adb shell cat /data/airos/auth_token.txt

# Or from logs
adb logcat -s AIROS:V | grep "Initial auth token"
```

#### 4. Test Connection
```python
# Using the Python client
from airos_client import AIROSClient

# Get device IP
# adb shell ip addr show wlan0

client = AIROSClient("192.168.1.100", "your-auth-token")
info = client.get_system_info()
print(f"Connected to AIROS {info.airos_version}")
```

### Phase 9: Development Workflow

#### 1. Making Changes to AI Agent
```bash
# Edit source files
vim packages/apps/AIROSAgent/src/com/airos/agent/AIAgentService.java

# Rebuild only the app
mmm packages/apps/AIROSAgent/

# Push to device
adb root
adb remount
adb push out/target/product/sunfish/system/priv-app/AIROSAgent/AIROSAgent.apk \
    /system/priv-app/AIROSAgent/

# Restart service
adb shell am force-stop com.airos.agent
adb shell am start-service com.airos.agent/.AIAgentService
```

#### 2. Testing Code Injection
```python
# Example: Modify SystemUI
client.create_snapshot("before_systemui_mod")

java_code = """
public class UIModifier {
    public static void injectCustomUI() {
        android.util.Log.d("AIROS", "Custom UI injected!");
        // Add your modifications here
    }
}
"""

success = client.inject_code(
    "com.android.systemui.SystemUIApplication",
    "onCreate",
    java_code
)

if not success:
    client.rollback("before_systemui_mod")
```

### Troubleshooting Guide

#### Common Issues and Solutions

**1. Build Failures**
```bash
# Clean build directory
make clean
make clobber

# Remove ccache if corrupted
ccache -C

# Increase swap if OOM
sudo dd if=/dev/zero of=/swapfile bs=1G count=16
sudo mkswap /swapfile
sudo swapon /swapfile
```

**2. Device Bootloop**
```bash
# Boot to fastboot
# Hold Power + Volume Down

# Flash stock boot image temporarily
fastboot flash boot stock_boot.img

# Or boot TWRP and restore
fastboot boot twrp.img
# Restore from TWRP backup
```

**3. AI Agent Service Not Starting**
```bash
# Check SELinux status
adb shell getenforce

# Set to permissive temporarily
adb shell su -c "setenforce 0"

# Check service logs
adb logcat -b all | grep -E "airos|AIROS"

# Manually start service
adb shell su -c "am startservice com.airos.agent/.AIAgentService"
```

**4. Network Connection Issues**
```bash
# Check firewall
adb shell iptables -L

# Add firewall rules
adb shell su -c "iptables -I INPUT -p tcp --dport 8080 -j ACCEPT"
adb shell su -c "iptables -I INPUT -p tcp --dport 8081 -j ACCEPT"

# Verify ports are open
adb shell netstat -tlpn | grep -E "8080|8081"
```

**5. Permission Denied Errors**
```bash
# Grant all permissions to AI Agent
adb shell pm grant com.airos.agent android.permission.WRITE_SECURE_SETTINGS
adb shell pm grant com.airos.agent android.permission.INSTALL_PACKAGES
adb shell pm grant com.airos.agent android.permission.DELETE_PACKAGES
```

### Security Warnings ⚠️

**IMPORTANT: This ROM is for experimental use only!**

1. **Never use on a daily driver device**
2. **Don't store personal data on the device**
3. **Disable all cloud sync services**
4. **Use on isolated network if possible**
5. **Be aware of these security implications:**
   - Root access exposed over network
   - SELinux in permissive mode
   - System signature verification disabled
   - Remote code execution enabled
   - No SafetyNet attestation

### Next Steps

1. **Enhance Security** (for production)
   - Implement proper authentication
   - Add TLS/SSL encryption
   - Create sandboxed execution environment
   - Implement rate limiting

2. **Add Features**
   - Multi-agent support
   - Cloud backup integration
   - Visual debugging interface
   - Automated testing framework

3. **Optimize Performance**
   - Reduce logging overhead
   - Implement caching
   - Optimize code injection
   - Add performance profiling

4. **Expand Device Support**
   - Port to other Pixel devices
   - Support for OnePlus devices
   - Generic GSI build