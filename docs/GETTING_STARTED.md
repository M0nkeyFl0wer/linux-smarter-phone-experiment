# Getting Started Linux Smart(er) Phone

## Choose Your Path

### 🧪 Path 1: Virtual Testing (No Phone Required)
Perfect for developers, researchers, or anyone wanting to explore AIROS without risking hardware.

**Time Required**: 30 minutes  
**Difficulty**: Easy  
**Risk**: None

[→ Go to Virtual Testing Guide](#virtual-testing)

### 📱 Path 2: Real Device Installation
Transform your phone into an AI-powered Linux device with Android app support.

**Time Required**: 60-90 minutes  
**Difficulty**: Medium  
**Risk**: Data loss, potential soft-brick (recoverable)

[→ Go to Device Installation Guide](#device-installation)

### 🔧 Path 3: Development Environment
Set up a development environment to contribute to AIROS.

**Time Required**: 45 minutes  
**Difficulty**: Easy-Medium  
**Risk**: None

[→ Go to Development Setup](#development-setup)

---

## Virtual Testing

### Option A: Docker (Fastest)

```bash
# 1. Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Logout and login again

# 2. Run AIROS simulator
docker run -it --rm \
  --name airos-test \
  -p 8080:8080 \
  -p 8081:8081 \
  -v ~/airos-data:/data \
  ghcr.io/airos/simulator:latest

# 3. Connect from another terminal
curl http://localhost:8080/api/system_info

# 4. Access Web UI
# Open browser: http://localhost:8080/ui
```

### Option B: QEMU/KVM (Full OS)

```bash
# 1. Install QEMU
sudo apt install qemu-kvm virt-manager

# 2. Download pre-built image
wget https://github.com/airos/images/releases/latest/download/airos-qemu-x86_64.qcow2

# 3. Run virtual machine
qemu-system-x86_64 \
  -enable-kvm \
  -m 4G \
  -smp 4 \
  -hda airos-qemu-x86_64.qcow2 \
  -netdev user,id=net0,hostfwd=tcp::8080-:8080 \
  -device e1000,netdev=net0 \
  -vnc :1

# 4. Connect via VNC
vncviewer localhost:1

# 5. SSH access (password: airos)
ssh user@localhost -p 2222
```

### Option C: Waydroid on Desktop

```bash
# 1. Install Waydroid (Ubuntu/Debian)
sudo apt install curl ca-certificates -y
curl -s https://repo.waydro.id/waydroid.gpg | sudo apt-key add -
echo "deb https://repo.waydro.id/ $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/waydroid.list
sudo apt update
sudo apt install waydroid -y

# 2. Initialize with AIROS modifications
git clone https://github.com/airos/waydroid-airos
cd waydroid-airos
./setup.sh

# 3. Start Waydroid
waydroid session start
waydroid show-full-ui

# 4. Install AIROS agent
./install-airos-agent.sh
```

---

## Device Installation

### Prerequisites Checklist

- [ ] Compatible device ([Check list](../install/DEVICE_SUPPORT.md))
- [ ] 70%+ battery charge
- [ ] USB cable (preferably original)
- [ ] 10GB free space on computer
- [ ] Backup of important data
- [ ] 60-90 minutes of time

### Step 1: Choose Your Device

#### Recommended Devices
1. **OnePlus 7 Pro** - Best overall support
2. **PinePhone/Pro** - Built for Linux
3. **Pixel 3a** - Good budget option

#### Check Your Device
```bash
# Connect phone and check model
adb shell getprop ro.product.model
adb shell getprop ro.product.device

# Verify in our database
./check-device-support.sh
```

### Step 2: Backup Your Data

```bash
# Create backup directory
mkdir ~/phone-backup
cd ~/phone-backup

# Pull important data
adb pull /sdcard/DCIM ./photos
adb pull /sdcard/Download ./downloads
adb pull /sdcard/Documents ./documents
adb pull /sdcard/WhatsApp ./whatsapp

# Create full backup (optional, large)
adb backup -apk -shared -all -system -f full-backup.ab
```

### Step 3: Run Interactive Installer

```bash
# Download installer
wget https://raw.githubusercontent.com/airos/airos/main/install.sh
chmod +x install.sh

# Run with logging
./install.sh | tee installation-log.txt

# Follow prompts:
# 1. Select device model
# 2. Choose OS (Ubuntu Touch recommended)
# 3. Confirm data wipe
# 4. Wait for installation
```

### Step 4: Post-Installation Setup

```bash
# Connect to device
ssh user@<device-ip>

# Verify AIROS is running
systemctl status airos-agent

# Get auth token
cat /etc/airos/config.yml | grep auth_token

# Test connection
curl http://<device-ip>:8080/api/system_info
```

---

## Development Setup

### 1. Fork and Clone Repository

```bash
# Fork on GitHub first, then:
git clone https://github.com/YOUR-USERNAME/airos.git
cd airos

# Add upstream remote
git remote add upstream https://github.com/airos/airos.git

# Create development branch
git checkout -b feature/my-feature
```

### 2. Set Up Development Environment

```bash
# Install dependencies
sudo apt install python3 python3-pip python3-venv \
                 android-tools-adb android-tools-fastboot \
                 docker.io docker-compose \
                 qemu-kvm virt-manager

# Create Python virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python packages
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Install pre-commit hooks
pre-commit install
```

### 3. Run Local Tests

```bash
# Unit tests
pytest tests/

# Integration tests
./run-integration-tests.sh

# Lint checks
flake8 src/
black --check src/
mypy src/

# Build Docker image
docker build -t airos-dev .

# Run in container
docker run -it --rm airos-dev
```

### 4. Test on Virtual Device

```bash
# Start QEMU test environment
./virtualization/start-test-vm.sh

# Deploy your changes
./deploy-to-vm.sh

# Run test suite
./test-on-vm.sh

# Check logs
./get-vm-logs.sh
```

### 5. Document Your Changes

```bash
# Update documentation
vim docs/YOUR-FEATURE.md

# Add to changelog
vim CHANGELOG.md

# Update tests
vim tests/test_your_feature.py

# Commit with conventional commits
git add .
git commit -m "feat: add amazing feature

- Detailed description
- What it does
- Why it's needed

Fixes #123"
```

---

## Quick Commands Reference

### Device Management
```bash
# Check device status
airos-cli status

# Install app with auto-fix
airos-cli install <app-name>

# Fix broken app
airos-cli fix <package-name>

# Monitor system
airos-cli monitor
```

### Development
```bash
# Build project
make build

# Run tests
make test

# Deploy to device
make deploy DEVICE=<ip-address>

# Clean build
make clean
```

### Troubleshooting
```bash
# View logs
airos-cli logs

# Reset AIROS
airos-cli reset

# Recovery mode
airos-cli recover

# Generate debug report
airos-cli debug-report
```

---

## Next Steps

### After Virtual Testing
1. Try different Linux distributions
2. Test Android app compatibility
3. Experiment with AI agent commands
4. Report findings in [Discussions](https://github.com/airos/airos/discussions)

### After Device Installation
1. Install your essential apps
2. Test banking/payment apps
3. Configure daily driver settings
4. Share your success story

### After Development Setup
1. Pick an issue from [Good First Issues](https://github.com/airos/airos/issues?label=good-first-issue)
2. Join our [Discord](https://discord.gg/airos) development channel
3. Submit your first pull request
4. Become a maintainer!

---

## Getting Help

### Quick Help
- **Discord**: [Join Server](https://discord.gg/airos) - Real-time chat
- **Matrix**: [#airos:matrix.org](https://matrix.to/#/#airos:matrix.org) - Decentralized chat
- **GitHub Issues**: [Report bugs](https://github.com/airos/airos/issues)

### Documentation
- [Full Documentation](../README.md)
- [API Reference](API_REFERENCE.md)
- [Troubleshooting Guide](../community/TROUBLESHOOTING.md)
- [FAQ](FAQ.md)

### Community Support
- Weekly office hours: Thursdays 6PM UTC
- Device-specific channels on Discord
- Regional language support available

---

## Safety Reminders

⚠️ **Before installing on a real device:**
- Backup all important data
- Have recovery tools ready
- Understand the risks
- Start with virtual testing if unsure

✅ **Safe practices:**
- Keep installation logs
- Join community before starting
- Have a backup phone available
- Don't rush the process

---

<p align="center">
  <b>Welcome to the AIROS community! 🚀</b>
  <br>
  <sub>You're about to transform mobile devices into AI research platforms</sub>
</p>
