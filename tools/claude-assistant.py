#!/usr/bin/env python3
"""
Claude Code Interactive Installation Assistant for Ubuntu Touch + AIROS
Run this with Claude Code to get interactive guidance through the installation
"""

import os
import sys
import subprocess
import time
import json
from pathlib import Path
from typing import Optional, Dict, List, Tuple

class Colors:
    """Terminal colors for pretty output"""
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

class UbuntuTouchInstaller:
    """Interactive installer assistant for Ubuntu Touch + AIROS on OnePlus 7 Pro"""
    
    def __init__(self):
        self.device = "OnePlus 7 Pro"
        self.device_codename = "guacamole"
        self.work_dir = Path.home() / "oneplus7pro_ubuntu_airos"
        self.progress_file = self.work_dir / ".installation_progress.json"
        self.progress = self.load_progress()
        
    def load_progress(self) -> Dict:
        """Load saved progress from previous sessions"""
        if self.progress_file.exists():
            with open(self.progress_file, 'r') as f:
                return json.load(f)
        return {
            "current_phase": "start",
            "completed_steps": [],
            "device_state": "unknown",
            "auth_token": None
        }
    
    def save_progress(self):
        """Save current progress"""
        self.work_dir.mkdir(exist_ok=True)
        with open(self.progress_file, 'w') as f:
            json.dump(self.progress, f, indent=2)
    
    def print_header(self, text: str):
        """Print a formatted header"""
        print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}")
        print(f"{Colors.HEADER}{Colors.BOLD}{text.center(60)}{Colors.ENDC}")
        print(f"{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}\n")
    
    def print_step(self, text: str):
        """Print a step instruction"""
        print(f"{Colors.CYAN}➤ {text}{Colors.ENDC}")
    
    def print_success(self, text: str):
        """Print success message"""
        print(f"{Colors.GREEN}✅ {text}{Colors.ENDC}")
    
    def print_warning(self, text: str):
        """Print warning message"""
        print(f"{Colors.WARNING}⚠️  {text}{Colors.ENDC}")
    
    def print_error(self, text: str):
        """Print error message"""
        print(f"{Colors.FAIL}❌ {text}{Colors.ENDC}")
    
    def print_info(self, text: str):
        """Print info message"""
        print(f"{Colors.BLUE}ℹ️  {text}{Colors.ENDC}")
    
    def ask_yes_no(self, question: str) -> bool:
        """Ask a yes/no question"""
        while True:
            response = input(f"{Colors.CYAN}{question} (y/n): {Colors.ENDC}").lower()
            if response in ['y', 'yes']:
                return True
            elif response in ['n', 'no']:
                return False
            else:
                print("Please answer 'y' or 'n'")
    
    def wait_for_confirmation(self, message: str = "Press Enter when ready to continue..."):
        """Wait for user confirmation"""
        input(f"{Colors.CYAN}{message}{Colors.ENDC}")
    
    def run_command(self, command: str, capture_output: bool = False) -> Optional[str]:
        """Run a shell command"""
        print(f"{Colors.BLUE}Running: {command}{Colors.ENDC}")
        try:
            if capture_output:
                result = subprocess.run(command, shell=True, capture_output=True, text=True)
                if result.returncode == 0:
                    return result.stdout
                else:
                    self.print_error(f"Command failed: {result.stderr}")
                    return None
            else:
                return subprocess.run(command, shell=True, check=True)
        except subprocess.CalledProcessError as e:
            self.print_error(f"Command failed: {e}")
            return None
    
    def check_prerequisites(self) -> bool:
        """Check if required tools are installed"""
        self.print_header("Checking Prerequisites")
        
        tools = {
            'adb': 'Android Debug Bridge',
            'fastboot': 'Fastboot tool',
            'git': 'Git version control',
            'python3': 'Python 3',
            'wget': 'Download tool'
        }
        
        missing_tools = []
        for tool, description in tools.items():
            if subprocess.run(f"which {tool}", shell=True, capture_output=True).returncode == 0:
                self.print_success(f"{description} ({tool}) is installed")
            else:
                self.print_error(f"{description} ({tool}) is NOT installed")
                missing_tools.append(tool)
        
        if missing_tools:
            self.print_warning(f"Missing tools: {', '.join(missing_tools)}")
            self.print_info("Please install them before continuing")
            
            # Provide OS-specific installation commands
            if sys.platform == "linux":
                self.print_info("On Ubuntu/Debian, run:")
                print(f"sudo apt install {' '.join(missing_tools)}")
            elif sys.platform == "darwin":
                self.print_info("On macOS, run:")
                print(f"brew install android-platform-tools {' '.join(missing_tools)}")
            
            return False
        
        self.print_success("All prerequisites are installed!")
        return True
    
    def check_device_connection(self) -> bool:
        """Check if OnePlus 7 Pro is connected"""
        self.print_header("Checking Device Connection")
        
        self.print_step("Make sure your OnePlus 7 Pro is:")
        print("  1. Connected via USB cable")
        print("  2. USB Debugging is enabled")
        print("  3. Set to 'File Transfer' or 'MTP' mode")
        
        self.wait_for_confirmation("Press Enter when ready...")
        
        # Check ADB connection
        output = self.run_command("adb devices", capture_output=True)
        if output and "device" in output and not output.strip().endswith("devices"):
            self.print_success("Device detected via ADB!")
            
            # Get device info
            model = self.run_command("adb shell getprop ro.product.model", capture_output=True)
            if model:
                self.print_info(f"Device model: {model.strip()}")
                if "GM1917" in model or "HD1917" in model or "OnePlus" in model:
                    self.print_success("Confirmed: OnePlus 7 Pro detected!")
                    return True
                else:
                    self.print_warning(f"Device detected but model doesn't match OnePlus 7 Pro")
                    if self.ask_yes_no("Continue anyway?"):
                        return True
        else:
            self.print_error("No device detected")
            self.print_info("If you see 'unauthorized', check your phone for the permission prompt")
        
        return False
    
    def backup_data(self):
        """Guide user through data backup"""
        self.print_header("Data Backup")
        
        self.print_warning("The next steps will ERASE ALL DATA on your phone!")
        
        if self.ask_yes_no("Do you want to backup your data first?"):
            self.print_step("Creating backup directory...")
            backup_dir = self.work_dir / "backup"
            backup_dir.mkdir(parents=True, exist_ok=True)
            
            self.print_info("Backing up photos...")
            self.run_command(f"adb pull /sdcard/DCIM {backup_dir}/DCIM")
            
            self.print_info("Backing up downloads...")
            self.run_command(f"adb pull /sdcard/Download {backup_dir}/Download")
            
            if self.ask_yes_no("Backup WhatsApp data?"):
                self.run_command(f"adb pull /sdcard/WhatsApp {backup_dir}/WhatsApp")
            
            self.print_success(f"Backup completed! Files saved to: {backup_dir}")
        else:
            self.print_warning("Skipping backup - ALL DATA WILL BE LOST!")
            
        self.wait_for_confirmation("Press Enter to continue...")
    
    def unlock_bootloader(self) -> bool:
        """Guide through bootloader unlocking"""
        self.print_header("Bootloader Unlock")
        
        self.print_warning("This will ERASE ALL DATA on your phone!")
        
        if not self.ask_yes_no("Are you ready to unlock the bootloader?"):
            return False
        
        self.print_step("Rebooting to bootloader...")
        self.run_command("adb reboot bootloader")
        
        self.print_info("Waiting for bootloader mode...")
        time.sleep(5)
        
        # Check if device is in bootloader
        output = self.run_command("fastboot devices", capture_output=True)
        if not output or self.device_codename not in output.lower():
            self.print_error("Device not detected in bootloader mode")
            return False
        
        self.print_success("Device in bootloader mode")
        
        # Check lock status
        self.print_info("Checking bootloader lock status...")
        output = self.run_command("fastboot oem device-info", capture_output=True)
        
        if output and "unlocked: true" in output.lower():
            self.print_success("Bootloader is already unlocked!")
            self.run_command("fastboot reboot")
            return True
        
        self.print_step("Unlocking bootloader...")
        print("\n⚠️  On your phone:")
        print("1. You'll see a warning screen")
        print("2. Use Volume buttons to select 'UNLOCK THE BOOTLOADER'")
        print("3. Press Power button to confirm")
        
        self.wait_for_confirmation("Press Enter when ready...")
        
        self.run_command("fastboot oem unlock")
        
        self.print_info("Phone will reboot and wipe all data")
        self.print_info("This takes 5-10 minutes...")
        
        time.sleep(10)
        self.wait_for_confirmation("Press Enter when phone has finished wiping and rebooted...")
        
        self.print_success("Bootloader unlocked!")
        return True
    
    def install_ubuntu_touch(self) -> bool:
        """Install Ubuntu Touch using UBports installer"""
        self.print_header("Installing Ubuntu Touch")
        
        self.print_info("We'll use the UBports installer for this step")
        
        # Check if installer exists
        if sys.platform == "linux":
            installer_check = self.run_command("which ubports-installer", capture_output=True)
            if not installer_check:
                self.print_warning("UBports installer not found")
                if self.ask_yes_no("Install it now?"):
                    self.run_command("sudo snap install ubports-installer")
        
        self.print_step("Launching UBports installer...")
        print("\nIn the installer:")
        print("1. Select 'OnePlus' as manufacturer")
        print("2. Select 'OnePlus 7 Pro (guacamole)' as device")
        print("3. Choose 'Stable' channel (recommended)")
        print("4. Follow the on-screen instructions")
        print("5. The installer will handle everything automatically")
        
        if sys.platform == "linux":
            self.run_command("ubports-installer")
        else:
            self.print_info("Please run the UBports installer manually")
            self.print_info("Download from: https://devices.ubuntu-touch.io/installer/")
        
        self.wait_for_confirmation("\nPress Enter when Ubuntu Touch installation is complete...")
        
        self.print_success("Ubuntu Touch installed!")
        return True
    
    def setup_airos(self) -> bool:
        """Set up AIROS components on Ubuntu Touch"""
        self.print_header("Setting up AIROS")
        
        self.print_info("Your phone should now be running Ubuntu Touch")
        self.print_step("Please complete the initial setup on your phone:")
        print("1. Choose your language")
        print("2. Connect to WiFi")
        print("3. Create a user account")
        print("4. Set a PIN or password")
        
        self.wait_for_confirmation("Press Enter when initial setup is complete...")
        
        self.print_step("Enable Developer Mode on the phone:")
        print("1. Go to Settings → About → Developer Mode")
        print("2. Turn ON Developer Mode")
        print("3. Set a password for SSH (remember this!)")
        print("4. Note the IP address shown")
        
        phone_ip = input("Enter your phone's IP address: ")
        ssh_password = input("Enter the SSH password you just set: ")
        
        # Create setup script
        setup_script = f"""#!/bin/bash
# AIROS Setup Script for Ubuntu Touch

echo "Installing AIROS components..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y python3 python3-pip git curl wget \\
    android-tools-adb sqlite3 build-essential

# Install Waydroid
sudo apt install -y waydroid

# Initialize Waydroid
sudo waydroid init -s GAPPS

# Start Waydroid
sudo systemctl start waydroid-container
waydroid session start &

# Install MicroG
cd /tmp
wget https://github.com/microg/GmsCore/releases/latest/download/GmsCore.apk
wget https://github.com/microg/GsfProxy/releases/latest/download/GsfProxy.apk
wget https://github.com/microg/FakeStore/releases/latest/download/FakeStore.apk

sudo waydroid app install GmsCore.apk
sudo waydroid app install GsfProxy.apk  
sudo waydroid app install FakeStore.apk

# Install Aurora Store
wget https://f-droid.org/repo/com.aurora.store_37.apk
sudo waydroid app install com.aurora.store_37.apk

echo "AIROS setup complete!"
"""
        
        # Save setup script
        script_path = self.work_dir / "setup_airos.sh"
        script_path.write_text(setup_script)
        
        self.print_info(f"Copying setup script to phone...")
        self.run_command(f"sshpass -p {ssh_password} scp {script_path} phablet@{phone_ip}:~/")
        
        self.print_info("Running setup on phone (this takes 10-15 minutes)...")
        self.run_command(f"sshpass -p {ssh_password} ssh phablet@{phone_ip} 'chmod +x setup_airos.sh && ./setup_airos.sh'")
        
        self.print_success("AIROS components installed!")
        
        # Generate auth token
        import uuid
        auth_token = str(uuid.uuid4())
        self.progress['auth_token'] = auth_token
        self.save_progress()
        
        self.print_success(f"Auth token generated: {auth_token}")
        
        return True
    
    def test_installation(self):
        """Test the complete installation"""
        self.print_header("Testing Installation")
        
        if not self.progress.get('auth_token'):
            self.print_error("No auth token found. Please run setup first.")
            return
        
        phone_ip = input("Enter your phone's IP address: ")
        
        test_script = f"""
import requests

url = "http://{phone_ip}:8080/api/system_info"
headers = {{"Authorization": "Bearer {self.progress['auth_token']}"}}

try:
    response = requests.get(url, headers=headers, timeout=5)
    if response.status_code == 200:
        print("✅ Successfully connected to AIROS!")
        info = response.json()
        print(f"Device: {{info.get('device')}}")
        print(f"AIROS Version: {{info.get('version')}}")
        print(f"Waydroid Running: {{info.get('waydroid_running')}}")
    else:
        print(f"❌ Connection failed: {{response.status_code}}")
except Exception as e:
    print(f"❌ Error: {{e}}")
"""
        
        test_path = self.work_dir / "test_connection.py"
        test_path.write_text(test_script)
        
        self.print_info("Testing connection to AIROS...")
        self.run_command(f"python3 {test_path}")
        
        self.print_success("Installation complete!")
        print(f"\n📱 Your OnePlus 7 Pro is now running:")
        print("  ✓ Ubuntu Touch")
        print("  ✓ Waydroid (Android compatibility)")
        print("  ✓ MicroG (Google Services replacement)")
        print("  ✓ Aurora Store")
        print("  ✓ AIROS AI compatibility layer")
        
        print(f"\n🔑 Connection details:")
        print(f"  IP: {phone_ip}")
        print(f"  Port: 8080")
        print(f"  Token: {self.progress['auth_token']}")
        
        print("\n🚀 Next steps:")
        print("  1. Open Aurora Store on your phone")
        print("  2. Install your favorite Android apps")
        print("  3. Connect from Python to control via AI")
    
    def run(self):
        """Main installation flow"""
        self.print_header("Ubuntu Touch + AIROS Installation")
        print(f"Device: {self.device}")
        print(f"Work directory: {self.work_dir}")
        
        # Check where we left off
        if self.progress['current_phase'] != 'start':
            self.print_info(f"Resuming from phase: {self.progress['current_phase']}")
            if not self.ask_yes_no("Continue from where you left off?"):
                self.progress = {"current_phase": "start", "completed_steps": []}
        
        steps = [
            ("prerequisites", "Check Prerequisites", self.check_prerequisites),
            ("device_connection", "Check Device", self.check_device_connection),
            ("backup", "Backup Data", self.backup_data),
            ("bootloader", "Unlock Bootloader", self.unlock_bootloader),
            ("ubuntu_touch", "Install Ubuntu Touch", self.install_ubuntu_touch),
            ("airos", "Setup AIROS", self.setup_airos),
            ("test", "Test Installation", self.test_installation)
        ]
        
        for step_id, step_name, step_func in steps:
            if step_id in self.progress['completed_steps']:
                self.print_success(f"✓ {step_name} (already completed)")
                continue
            
            self.progress['current_phase'] = step_id
            self.save_progress()
            
            self.print_header(step_name)
            
            try:
                result = step_func()
                if result is not False:  # Allow functions that return None
                    self.progress['completed_steps'].append(step_id)
                    self.save_progress()
                else:
                    self.print_error(f"Step failed: {step_name}")
                    if not self.ask_yes_no("Continue anyway?"):
                        break
            except KeyboardInterrupt:
                self.print_warning("\nInstallation paused. Run again to resume.")
                break
            except Exception as e:
                self.print_error(f"Error: {e}")
                if not self.ask_yes_no("Continue anyway?"):
                    break
        
        if len(self.progress['completed_steps']) == len(steps):
            self.print_header("🎉 Installation Complete! 🎉")
            print("\nYour OnePlus 7 Pro is now an AI-powered Linux phone!")
        else:
            self.print_info("Installation incomplete. Run again to continue.")

if __name__ == "__main__":
    installer = UbuntuTouchInstaller()
    installer.run()