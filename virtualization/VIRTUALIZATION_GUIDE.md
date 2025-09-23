# AIROS Virtualization & Testing Guide

## Overview

Test and develop AIROS without physical devices using various virtualization methods. Perfect for:
- 🧪 Testing before committing to hardware
- 🔧 Development and debugging
- 📚 Learning and experimentation  
- 🎓 Education and demonstrations

## Virtualization Options Comparison

| Method | Setup Time | Realism | Performance | Use Case |
|--------|------------|---------|-------------|----------|
| **Docker** | 5 min | Low | Excellent | Quick API testing |
| **QEMU/KVM** | 20 min | High | Good | Full OS testing |
| **VirtualBox** | 15 min | High | Good | GUI development |
| **Waydroid** | 10 min | Medium | Excellent | App compatibility |
| **Cloud VMs** | 30 min | High | Variable | Team development |

---

## Method 1: Docker Containers

### Quick Start (5 minutes)

```bash
# Pull and run AIROS simulator
docker run -it --rm \
  --name airos-sim \
  -p 8080:8080 \
  -p 8081:8081 \
  ghcr.io/airos/simulator:latest

# Test from another terminal
curl http://localhost:8080/api/system_info
```

### Advanced Docker Setup

```yaml
# docker-compose.yml
version: '3.8'

services:
  airos-agent:
    image: ghcr.io/airos/agent:latest
    container_name: airos-agent
    privileged: true
    ports:
      - "8080:8080"
      - "8081:8081"
    volumes:
      - ./data:/var/lib/airos
      - ./config:/etc/airos
    environment:
      - AIROS_MODE=development
      - ENABLE_DEBUG=true
      - AUTO_FIX=true
    networks:
      - airos-net

  waydroid:
    image: ghcr.io/airos/waydroid:latest
    container_name: airos-waydroid
    privileged: true
    devices:
      - /dev/kvm
    volumes:
      - waydroid-data:/var/lib/waydroid
    networks:
      - airos-net

  microg:
    image: ghcr.io/airos/microg:latest
    container_name: airos-microg
    depends_on:
      - waydroid
    networks:
      - airos-net

volumes:
  waydroid-data:

networks:
  airos-net:
    driver: bridge
```

```bash
# Run complete stack
docker-compose up -d

# View logs
docker-compose logs -f

# Access shell
docker exec -it airos-agent bash

# Stop everything
docker-compose down
```

### Building Custom Docker Images

```dockerfile
# Dockerfile.development
FROM ubuntu:22.04

# Install base dependencies
RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    android-tools-adb \
    git wget curl \
    build-essential

# Install AIROS
WORKDIR /opt/airos
COPY . .
RUN pip3 install -r requirements.txt
RUN ./install.sh --docker

# Configure
COPY config/docker.yml /etc/airos/config.yml

# Expose ports
EXPOSE 8080 8081

# Run agent
CMD ["python3", "/opt/airos/airos_agent.py"]
```

---

## Method 2: QEMU/KVM Full System Emulation

### Installation

```bash
# Ubuntu/Debian
sudo apt install qemu-kvm virt-manager bridge-utils \
                 cpu-checker libvirt-daemon-system

# Verify KVM support
kvm-ok

# Add user to groups
sudo usermod -aG libvirt,kvm $USER
# Logout and login again
```

### Download Pre-built Images

```bash
# Create images directory
mkdir -p ~/airos-vms
cd ~/airos-vms

# Download images
wget https://github.com/airos/images/releases/latest/download/airos-ubuntutouch-x86_64.qcow2
wget https://github.com/airos/images/releases/latest/download/airos-postmarketos-x86_64.qcow2
wget https://github.com/airos/images/releases/latest/download/airos-droidian-x86_64.qcow2
```

### Run Virtual Machines

```bash
#!/bin/bash
# run-airos-vm.sh

IMAGE="airos-ubuntutouch-x86_64.qcow2"
RAM="4G"
CPUS="4"
VNC_PORT="5901"
SSH_PORT="2222"
AIROS_PORT="8080"

qemu-system-x86_64 \
  -enable-kvm \
  -m $RAM \
  -smp $CPUS \
  -cpu host \
  -drive file=$IMAGE,format=qcow2 \
  -netdev user,id=net0,hostfwd=tcp::$SSH_PORT-:22,hostfwd=tcp::$AIROS_PORT-:8080 \
  -device virtio-net,netdev=net0 \
  -display vnc=:1 \
  -usb -device usb-tablet \
  -soundhw hda \
  -vga virtio

echo "VM Started!"
echo "VNC: localhost:$VNC_PORT"
echo "SSH: ssh user@localhost -p $SSH_PORT"
echo "AIROS: http://localhost:$AIROS_PORT"
```

### Using Virt-Manager (GUI)

```bash
# Launch virt-manager
virt-manager

# Create new VM:
# 1. File → New Virtual Machine
# 2. Import existing disk image
# 3. Browse → Select AIROS qcow2 image
# 4. Set RAM: 4096 MB minimum
# 5. Set CPUs: 2-4 cores
# 6. Name: AIROS-Test
# 7. Finish

# Configure network:
# 1. Open VM settings
# 2. Add Hardware → Network
# 3. Network source: Bridge
# 4. Device model: virtio
```

### ARM Device Emulation

```bash
# Emulate OnePlus 7 Pro (ARM64)
qemu-system-aarch64 \
  -M virt \
  -cpu cortex-a72 \
  -m 4G \
  -smp 8 \
  -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
  -drive file=airos-op7pro-arm64.qcow2,format=qcow2 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080 \
  -device virtio-net-device,netdev=net0 \
  -nographic

# Connect via SSH
ssh user@localhost -p 2222
```

---

## Method 3: Waydroid on Desktop Linux

### Installation Script

```bash
#!/bin/bash
# setup-waydroid-desktop.sh

set -e

echo "Installing Waydroid on Desktop Linux..."

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
fi

# Install Waydroid
case $OS in
    ubuntu|debian)
        curl -s https://repo.waydro.id/waydroid.gpg | sudo apt-key add -
        echo "deb https://repo.waydro.id/ $(lsb_release -cs) main" | \
            sudo tee /etc/apt/sources.list.d/waydroid.list
        sudo apt update
        sudo apt install waydroid -y
        ;;
    
    arch|manjaro)
        yay -S waydroid
        ;;
    
    fedora)
        sudo dnf copr enable aleasto/waydroid
        sudo dnf install waydroid
        ;;
esac

# Configure kernel modules
sudo modprobe binder_linux
sudo modprobe ashmem_linux
echo "binder_linux" | sudo tee -a /etc/modules
echo "ashmem_linux" | sudo tee -a /etc/modules

# Initialize Waydroid
sudo waydroid init -s GAPPS

# Install AIROS components
git clone https://github.com/airos/waydroid-airos
cd waydroid-airos
./install-airos.sh

# Start services
sudo systemctl enable waydroid-container
sudo systemctl start waydroid-container
waydroid session start &

echo "Waydroid + AIROS installed!"
echo "Run: waydroid show-full-ui"
```

### Waydroid Configuration

```ini
# ~/.config/waydroid/waydroid.cfg
[waydroid]
arch = x86_64
vendor_type = MAINLINE
system_datetime = AUTO
vendor_datetime = AUTO
suspend_action = freeze

[properties]
ro.hardware.gralloc = default
ro.hardware.egl = mesa
persist.waydroid.width = 1080
persist.waydroid.height = 1920
persist.waydroid.multi_windows = true
persist.waydroid.fake_touch = true
```

### Running Android Apps

```bash
# Show Android UI
waydroid show-full-ui

# Install APK
waydroid app install app.apk

# Launch app
waydroid app launch com.example.app

# List installed apps
waydroid app list

# Access shell
waydroid shell

# Install Aurora Store
wget https://f-droid.org/repo/com.aurora.store_37.apk
waydroid app install com.aurora.store_37.apk
```

---

## Method 4: VirtualBox

### Create AIROS VM

```bash
# Download VirtualBox image
wget https://github.com/airos/images/releases/latest/download/airos-virtualbox.ova

# Import OVA
VBoxManage import airos-virtualbox.ova

# Configure VM
VBoxManage modifyvm "AIROS" \
  --memory 4096 \
  --cpus 4 \
  --vram 128 \
  --accelerate3d on \
  --clipboard bidirectional \
  --draganddrop bidirectional

# Set up port forwarding
VBoxManage modifyvm "AIROS" \
  --natpf1 "ssh,tcp,,2222,,22" \
  --natpf1 "airos,tcp,,8080,,8080" \
  --natpf1 "websocket,tcp,,8081,,8081"

# Start VM
VBoxManage startvm "AIROS"
```

---

## Method 5: Cloud Testing

### Google Cloud Platform

```bash
# Create VM instance
gcloud compute instances create airos-test \
  --machine-type=n1-standard-4 \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=50GB \
  --enable-nested-virtualization \
  --tags=airos

# Configure firewall
gcloud compute firewall-rules create airos-ports \
  --allow tcp:8080,tcp:8081,tcp:22 \
  --target-tags=airos

# SSH to instance
gcloud compute ssh airos-test

# Install AIROS
curl -sSL https://raw.githubusercontent.com/airos/airos/main/install-cloud.sh | bash
```

### AWS EC2

```bash
# Launch instance using AWS CLI
aws ec2 run-instances \
  --image-id ami-0c94855ba95c574c8 \
  --instance-type t3.xlarge \
  --key-name your-key \
  --security-group-ids sg-xxxxxx \
  --block-device-mappings DeviceName=/dev/sda1,Ebs={VolumeSize=50} \
  --user-data file://airos-cloud-init.yaml
```

---

## Testing Scenarios

### 1. Basic Functionality Test

```python
#!/usr/bin/env python3
# test-airos-basic.py

import requests
import json
import time

AIROS_URL = "http://localhost:8080"
AUTH_TOKEN = "test-token"

def test_connection():
    """Test basic connectivity"""
    response = requests.get(f"{AIROS_URL}/api/system_info")
    assert response.status_code == 200
    info = response.json()
    print(f"✓ Connected to AIROS {info['version']}")
    return info

def test_waydroid():
    """Test Waydroid functionality"""
    response = requests.post(
        f"{AIROS_URL}/api/waydroid/status",
        headers={"Authorization": f"Bearer {AUTH_TOKEN}"}
    )
    assert response.status_code == 200
    status = response.json()
    print(f"✓ Waydroid running: {status['running']}")
    return status

def test_app_install():
    """Test app installation"""
    response = requests.post(
        f"{AIROS_URL}/api/install_app",
        headers={"Authorization": f"Bearer {AUTH_TOKEN}"},
        json={"package": "F-Droid", "auto_fix": True}
    )
    assert response.status_code == 200
    print("✓ App installation working")

def test_ai_fixing():
    """Test AI compatibility fixing"""
    response = requests.post(
        f"{AIROS_URL}/api/fix_app",
        headers={"Authorization": f"Bearer {AUTH_TOKEN}"},
        json={"package_name": "com.whatsapp"}
    )
    assert response.status_code == 200
    fixes = response.json()
    print(f"✓ AI fixing: {len(fixes['fixes_applied'])} fixes applied")

if __name__ == "__main__":
    print("Testing AIROS Virtual Instance...")
    test_connection()
    test_waydroid()
    test_app_install()
    test_ai_fixing()
    print("\n✅ All tests passed!")
```

### 2. Load Testing

```bash
# Install Apache Bench
sudo apt install apache2-utils

# Test API performance
ab -n 1000 -c 10 \
   -H "Authorization: Bearer test-token" \
   http://localhost:8080/api/system_info

# Monitor resource usage
htop
docker stats
```

### 3. App Compatibility Testing

```python
# test-apps.py
APPS_TO_TEST = [
    "com.whatsapp",
    "com.instagram.android",
    "com.spotify.music",
    "com.netflix.mediaclient",
    "com.ubercab",
    "com.discord",
    "org.telegram.messenger",
    "com.microsoft.teams"
]

for app in APPS_TO_TEST:
    print(f"Testing {app}...")
    
    # Install
    install_response = install_app(app)
    
    # Launch
    launch_response = launch_app(app)
    
    # Monitor for crashes
    time.sleep(30)
    crashes = check_crashes(app)
    
    # Apply fixes if needed
    if crashes:
        fixes = apply_fixes(app)
        print(f"  Applied {len(fixes)} fixes")
    
    # Test again
    test_app_functionality(app)
```

---

## Development Workflow

### 1. Local Development Cycle

```bash
# Edit code
vim src/airos_agent.py

# Build Docker image
docker build -t airos-dev .

# Run tests
docker run --rm airos-dev pytest

# Deploy to VM
./deploy-to-vm.sh 192.168.122.100

# Test changes
./test-on-vm.sh
```

### 2. CI/CD Pipeline

```yaml
# .github/workflows/test.yml
name: Test AIROS

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Build Docker image
      run: docker build -t airos-test .
    
    - name: Run unit tests
      run: docker run --rm airos-test pytest tests/unit
    
    - name: Run integration tests
      run: |
        docker-compose up -d
        sleep 30
        docker run --rm --network host airos-test pytest tests/integration
    
    - name: Test in QEMU
      run: |
        ./virtualization/test-in-qemu.sh
```

---

## Troubleshooting Virtual Environments

### Docker Issues

```bash
# Permission denied
sudo usermod -aG docker $USER
newgrp docker

# Container won't start
docker logs airos-sim
docker inspect airos-sim

# Reset everything
docker system prune -a
```

### QEMU/KVM Issues

```bash
# No KVM support
# Check CPU virtualization in BIOS
egrep -c '(vmx|svm)' /proc/cpuinfo

# Poor performance
# Use virtio drivers
-device virtio-net
-device virtio-blk

# Can't connect to VM
# Check iptables
sudo iptables -L
```

### Waydroid Issues

```bash
# Waydroid won't start
sudo modprobe binder_linux
sudo modprobe ashmem_linux

# Graphics issues
# Switch renderer
waydroid prop set renderer mesa

# Network issues
sudo waydroid shell settings put global captive_portal_detection_enabled 0
```

---

## Performance Optimization

### Docker Optimization

```yaml
# docker-compose.yml
services:
  airos:
    # Limit resources
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          memory: 1G
```

### QEMU Optimization

```bash
# Enable hardware acceleration
-enable-kvm -cpu host

# Use virtio for best performance
-device virtio-net
-device virtio-blk
-device virtio-gpu

# Increase RAM
-m 8G

# Pin to CPU cores
-smp 4,sockets=1,cores=4,threads=1
```

---

## Resources

### Pre-built Images
- [Ubuntu Touch x86_64](https://github.com/airos/images/releases)
- [PostmarketOS x86_64](https://github.com/airos/images/releases)
- [Droidian x86_64](https://github.com/airos/images/releases)

### Scripts and Tools
- [Automation Scripts](https://github.com/airos/airos/tree/main/virtualization/scripts)
- [Test Suites](https://github.com/airos/airos/tree/main/tests)
- [Performance Benchmarks](https://github.com/airos/airos/tree/main/benchmarks)

### Documentation
- [QEMU Documentation](https://www.qemu.org/docs/master/)
- [Docker Documentation](https://docs.docker.com/)
- [Waydroid Documentation](https://docs.waydro.id/)

---

<p align="center">
  <b>Happy Testing! 🧪</b>
  <br>
  <sub>Test in virtual, deploy to physical</sub>
</p>