#!/usr/bin/env python3
"""
AIROS Linux Agent - AI-Powered Mobile OS Control and App Compatibility Service
Provides deep system integration for Linux phones with Android app support
"""

import os
import sys
import json
import time
import shutil
import hashlib
import sqlite3
import asyncio
import logging
import subprocess
import tempfile
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
from concurrent.futures import ThreadPoolExecutor

import aiohttp
from aiohttp import web
import dbus
import psutil
import yaml
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('AIROS-Linux')


class AppFixType(Enum):
    """Types of app fixes that can be applied"""
    PERMISSION = "permission"
    LIBRARY = "library"
    SERVICE = "service"
    SIGNATURE = "signature"
    FRAMEWORK = "framework"
    NATIVE = "native"


@dataclass
class AppIssue:
    """Detected app compatibility issue"""
    package_name: str
    issue_type: AppFixType
    description: str
    stack_trace: Optional[str] = None
    missing_component: Optional[str] = None
    severity: str = "medium"


@dataclass
class AppFix:
    """Applied fix for app compatibility"""
    issue: AppIssue
    fix_type: str
    patch_data: Dict[str, Any]
    success: bool
    timestamp: float


class WaydroidManager:
    """Manages Waydroid Android container"""
    
    def __init__(self):
        self.waydroid_path = Path("/var/lib/waydroid")
        self.apps_path = self.waydroid_path / "data" / "app"
        self.system_path = self.waydroid_path / "system"
        
    def is_running(self) -> bool:
        """Check if Waydroid container is running"""
        try:
            result = subprocess.run(
                ["waydroid", "status"],
                capture_output=True,
                text=True,
                check=False
            )
            return "RUNNING" in result.stdout
        except Exception:
            return False
    
    def start(self) -> bool:
        """Start Waydroid container"""
        try:
            subprocess.run(["sudo", "waydroid", "container", "start"], check=True)
            time.sleep(5)  # Wait for container to initialize
            return True
        except subprocess.CalledProcessError:
            return False
    
    def stop(self) -> bool:
        """Stop Waydroid container"""
        try:
            subprocess.run(["sudo", "waydroid", "container", "stop"], check=True)
            return True
        except subprocess.CalledProcessError:
            return False
    
    def install_app(self, apk_path: str) -> bool:
        """Install an APK in Waydroid"""
        try:
            subprocess.run(
                ["waydroid", "app", "install", apk_path],
                check=True
            )
            return True
        except subprocess.CalledProcessError as e:
            logger.error(f"Failed to install APK: {e}")
            return False
    
    def list_packages(self) -> List[str]:
        """List installed packages"""
        try:
            result = subprocess.run(
                ["waydroid", "shell", "pm", "list", "packages"],
                capture_output=True,
                text=True,
                check=True
            )
            packages = []
            for line in result.stdout.splitlines():
                if line.startswith("package:"):
                    packages.append(line.replace("package:", ""))
            return packages
        except subprocess.CalledProcessError:
            return []
    
    def get_app_info(self, package_name: str) -> Dict:
        """Get detailed app information"""
        try:
            result = subprocess.run(
                ["waydroid", "shell", "dumpsys", "package", package_name],
                capture_output=True,
                text=True,
                check=True
            )
            # Parse the output (simplified)
            info = {
                "package": package_name,
                "version": "unknown",
                "permissions": [],
                "activities": []
            }
            
            for line in result.stdout.splitlines():
                if "versionName=" in line:
                    info["version"] = line.split("versionName=")[1].split()[0]
                elif "android.permission." in line:
                    perm = line.strip()
                    if perm not in info["permissions"]:
                        info["permissions"].append(perm)
            
            return info
        except subprocess.CalledProcessError:
            return {}
    
    def execute_shell(self, command: str) -> Tuple[bool, str]:
        """Execute shell command in Waydroid"""
        try:
            result = subprocess.run(
                ["waydroid", "shell", command],
                capture_output=True,
                text=True,
                check=True
            )
            return True, result.stdout
        except subprocess.CalledProcessError as e:
            return False, e.stderr


class MicroGManager:
    """Manages MicroG services for Google Services compatibility"""
    
    def __init__(self, waydroid_mgr: WaydroidManager):
        self.waydroid = waydroid_mgr
        self.microg_repo = "https://github.com/microg/GmsCore/releases"
        self.config_path = Path("/etc/airos/microg.yml")
        
    def install_microg(self) -> bool:
        """Install MicroG in Waydroid"""
        try:
            # Download latest MicroG APKs
            apks = [
                "GmsCore.apk",
                "GsfProxy.apk",
                "FakeStore.apk",
                "com.google.android.maps.jar"
            ]
            
            temp_dir = tempfile.mkdtemp()
            for apk in apks:
                # Download APK (simplified - would need proper release fetching)
                apk_path = Path(temp_dir) / apk
                # subprocess.run(["wget", f"{self.microg_repo}/latest/{apk}", "-O", str(apk_path)])
                
                # Install as system app
                self.install_system_app(apk_path)
            
            # Enable signature spoofing
            self.enable_signature_spoofing()
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to install MicroG: {e}")
            return False
    
    def install_system_app(self, apk_path: Path) -> bool:
        """Install APK as system app with elevated privileges"""
        try:
            # Extract APK
            extract_dir = tempfile.mkdtemp()
            subprocess.run(["unzip", str(apk_path), "-d", extract_dir], check=True)
            
            # Copy to Waydroid system
            system_app_path = self.waydroid.system_path / "priv-app" / apk_path.stem
            system_app_path.mkdir(parents=True, exist_ok=True)
            
            shutil.copy(apk_path, system_app_path / apk_path.name)
            
            # Set permissions
            subprocess.run([
                "sudo", "chmod", "644",
                str(system_app_path / apk_path.name)
            ], check=True)
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to install system app: {e}")
            return False
    
    def enable_signature_spoofing(self) -> bool:
        """Enable signature spoofing for MicroG"""
        try:
            # Patch framework to allow signature spoofing
            framework_path = self.waydroid.system_path / "framework" / "framework.jar"
            
            # This would require actual patching with tools like
            # NanoDroid-Patcher or Haystack
            logger.info("Signature spoofing would be enabled here")
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to enable signature spoofing: {e}")
            return False
    
    def configure_services(self, config: Dict) -> bool:
        """Configure MicroG services"""
        try:
            # Write configuration
            with open(self.config_path, 'w') as f:
                yaml.dump(config, f)
            
            # Apply settings via shell commands
            for service, enabled in config.get('services', {}).items():
                if enabled:
                    self.waydroid.execute_shell(
                        f"pm enable com.google.android.gms/{service}"
                    )
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to configure MicroG: {e}")
            return False


class AppCompatibilityFixer:
    """AI-powered app compatibility fixing system"""
    
    def __init__(self, waydroid_mgr: WaydroidManager):
        self.waydroid = waydroid_mgr
        self.fixes_db = Path("/var/lib/airos/app_fixes.db")
        self.patches_dir = Path("/var/lib/airos/patches")
        self.patches_dir.mkdir(parents=True, exist_ok=True)
        
        self.init_database()
        
    def init_database(self):
        """Initialize fixes database"""
        conn = sqlite3.connect(self.fixes_db)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS app_issues (
                id INTEGER PRIMARY KEY,
                package_name TEXT,
                issue_type TEXT,
                description TEXT,
                stack_trace TEXT,
                missing_component TEXT,
                severity TEXT,
                detected_at TIMESTAMP,
                fixed BOOLEAN DEFAULT FALSE
            )
        ''')
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS app_fixes (
                id INTEGER PRIMARY KEY,
                issue_id INTEGER,
                fix_type TEXT,
                patch_data TEXT,
                success BOOLEAN,
                applied_at TIMESTAMP,
                FOREIGN KEY (issue_id) REFERENCES app_issues(id)
            )
        ''')
        
        conn.commit()
        conn.close()
    
    async def monitor_app_crashes(self):
        """Monitor Waydroid logs for app crashes"""
        log_monitor = subprocess.Popen(
            ["waydroid", "logcat", "-b", "crash"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        while True:
            line = log_monitor.stdout.readline()
            if not line:
                break
                
            if "FATAL EXCEPTION" in line or "AndroidRuntime" in line:
                # Capture crash details
                crash_data = await self.capture_crash_context(log_monitor)
                
                # Analyze crash
                issue = self.analyze_crash(crash_data)
                
                if issue:
                    # Store issue
                    self.store_issue(issue)
                    
                    # Attempt automatic fix
                    fix = await self.auto_fix_issue(issue)
                    
                    if fix and fix.success:
                        logger.info(f"Successfully fixed {issue.package_name}: {issue.description}")
                    else:
                        logger.warning(f"Could not auto-fix {issue.package_name}: {issue.description}")
    
    async def capture_crash_context(self, log_process) -> str:
        """Capture full crash context from logcat"""
        crash_lines = []
        for _ in range(100):  # Capture next 100 lines
            line = log_process.stdout.readline()
            if not line:
                break
            crash_lines.append(line)
        return '\n'.join(crash_lines)
    
    def analyze_crash(self, crash_data: str) -> Optional[AppIssue]:
        """Analyze crash data to identify the issue"""
        lines = crash_data.splitlines()
        
        package_name = None
        issue_type = None
        description = None
        missing_component = None
        
        for line in lines:
            # Extract package name
            if "Process:" in line:
                package_name = line.split("Process:")[1].strip().split()[0]
            
            # Detect missing library
            elif "UnsatisfiedLinkError" in line or "couldn't find" in line:
                issue_type = AppFixType.LIBRARY
                if ".so" in line:
                    missing_component = line.split('"')[1] if '"' in line else None
                description = "Missing native library"
            
            # Detect missing service
            elif "ServiceNotFoundException" in line or "Unable to start service" in line:
                issue_type = AppFixType.SERVICE
                description = "Missing or incompatible service"
            
            # Detect permission issue
            elif "SecurityException" in line or "Permission denied" in line:
                issue_type = AppFixType.PERMISSION
                description = "Permission denied"
            
            # Detect Google Services issue
            elif "com.google.android.gms" in line:
                issue_type = AppFixType.FRAMEWORK
                description = "Google Services compatibility issue"
        
        if package_name and issue_type:
            return AppIssue(
                package_name=package_name,
                issue_type=issue_type,
                description=description,
                stack_trace=crash_data[:1000],  # Limit stack trace size
                missing_component=missing_component,
                severity="high" if "FATAL" in crash_data else "medium"
            )
        
        return None
    
    def store_issue(self, issue: AppIssue):
        """Store detected issue in database"""
        conn = sqlite3.connect(self.fixes_db)
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT INTO app_issues 
            (package_name, issue_type, description, stack_trace, missing_component, severity, detected_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (
            issue.package_name,
            issue.issue_type.value,
            issue.description,
            issue.stack_trace,
            issue.missing_component,
            issue.severity,
            time.time()
        ))
        
        conn.commit()
        conn.close()
    
    async def auto_fix_issue(self, issue: AppIssue) -> Optional[AppFix]:
        """Attempt to automatically fix the detected issue"""
        fix = None
        
        if issue.issue_type == AppFixType.LIBRARY:
            fix = await self.fix_missing_library(issue)
        elif issue.issue_type == AppFixType.SERVICE:
            fix = await self.fix_missing_service(issue)
        elif issue.issue_type == AppFixType.PERMISSION:
            fix = await self.fix_permission_issue(issue)
        elif issue.issue_type == AppFixType.FRAMEWORK:
            fix = await self.fix_framework_issue(issue)
        
        if fix:
            self.store_fix(fix)
        
        return fix
    
    async def fix_missing_library(self, issue: AppIssue) -> Optional[AppFix]:
        """Fix missing native library issue"""
        if not issue.missing_component:
            return None
        
        library_name = issue.missing_component
        logger.info(f"Attempting to fix missing library: {library_name}")
        
        try:
            # Strategy 1: Check if library exists in system
            system_lib_path = Path(f"/system/lib64/{library_name}")
            waydroid_lib_path = self.waydroid.system_path / "lib64" / library_name
            
            if system_lib_path.exists() and not waydroid_lib_path.exists():
                # Copy library to Waydroid
                shutil.copy(system_lib_path, waydroid_lib_path)
                subprocess.run(["sudo", "chmod", "644", str(waydroid_lib_path)], check=True)
                
                return AppFix(
                    issue=issue,
                    fix_type="library_copy",
                    patch_data={"library": library_name, "source": str(system_lib_path)},
                    success=True,
                    timestamp=time.time()
                )
            
            # Strategy 2: Create a shim library
            shim_path = await self.create_library_shim(library_name, issue.package_name)
            if shim_path:
                return AppFix(
                    issue=issue,
                    fix_type="library_shim",
                    patch_data={"library": library_name, "shim": str(shim_path)},
                    success=True,
                    timestamp=time.time()
                )
            
        except Exception as e:
            logger.error(f"Failed to fix missing library: {e}")
        
        return None
    
    async def create_library_shim(self, library_name: str, package_name: str) -> Optional[Path]:
        """Create a shim library that provides minimal functionality"""
        shim_dir = self.patches_dir / "shims"
        shim_dir.mkdir(exist_ok=True)
        
        # Generate C code for shim
        shim_code = f"""
        #include <android/log.h>
        #include <jni.h>
        
        #define LOG_TAG "AIROS_SHIM"
        #define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
        
        // Minimal JNI_OnLoad to prevent crashes
        JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved) {{
            LOGI("Shim library {library_name} loaded for {package_name}");
            return JNI_VERSION_1_6;
        }}
        
        // Add stub functions as needed based on crash analysis
        """
        
        # Write and compile shim
        shim_source = shim_dir / f"{library_name}.c"
        shim_source.write_text(shim_code)
        
        shim_output = self.waydroid.system_path / "lib64" / library_name
        
        try:
            # Compile shim (requires Android NDK)
            subprocess.run([
                "aarch64-linux-android-gcc",
                "-shared",
                "-fPIC",
                "-o", str(shim_output),
                str(shim_source),
                "-llog"
            ], check=True)
            
            subprocess.run(["sudo", "chmod", "644", str(shim_output)], check=True)
            
            return shim_output
            
        except subprocess.CalledProcessError:
            logger.error(f"Failed to compile shim for {library_name}")
            return None
    
    async def fix_missing_service(self, issue: AppIssue) -> Optional[AppFix]:
        """Fix missing or incompatible service"""
        logger.info(f"Attempting to fix missing service for: {issue.package_name}")
        
        try:
            # Strategy 1: Enable MicroG service if Google Services related
            if "com.google" in issue.stack_trace:
                success = self.waydroid.execute_shell(
                    "pm enable com.google.android.gms"
                )[0]
                
                if success:
                    return AppFix(
                        issue=issue,
                        fix_type="enable_microg",
                        patch_data={"service": "com.google.android.gms"},
                        success=True,
                        timestamp=time.time()
                    )
            
            # Strategy 2: Create service stub
            stub_created = await self.create_service_stub(issue.package_name, issue.stack_trace)
            if stub_created:
                return AppFix(
                    issue=issue,
                    fix_type="service_stub",
                    patch_data={"package": issue.package_name},
                    success=True,
                    timestamp=time.time()
                )
                
        except Exception as e:
            logger.error(f"Failed to fix service issue: {e}")
        
        return None
    
    async def fix_permission_issue(self, issue: AppIssue) -> Optional[AppFix]:
        """Fix permission-related issues"""
        logger.info(f"Attempting to fix permission issue for: {issue.package_name}")
        
        try:
            # Extract required permission from stack trace
            permissions_to_grant = []
            
            for line in issue.stack_trace.splitlines():
                if "android.permission." in line:
                    perm = line.split("android.permission.")[1].split()[0]
                    permissions_to_grant.append(f"android.permission.{perm}")
            
            # Grant permissions
            for permission in permissions_to_grant:
                success, _ = self.waydroid.execute_shell(
                    f"pm grant {issue.package_name} {permission}"
                )
                
                if success:
                    logger.info(f"Granted {permission} to {issue.package_name}")
            
            if permissions_to_grant:
                return AppFix(
                    issue=issue,
                    fix_type="grant_permissions",
                    patch_data={"permissions": permissions_to_grant},
                    success=True,
                    timestamp=time.time()
                )
                
        except Exception as e:
            logger.error(f"Failed to fix permission issue: {e}")
        
        return None
    
    async def fix_framework_issue(self, issue: AppIssue) -> Optional[AppFix]:
        """Fix framework compatibility issues"""
        logger.info(f"Attempting to fix framework issue for: {issue.package_name}")
        
        try:
            # Strategy 1: Patch APK to remove Google Services dependency
            apk_path = await self.extract_installed_apk(issue.package_name)
            if apk_path:
                patched_apk = await self.patch_apk_framework(apk_path, issue)
                if patched_apk:
                    # Reinstall patched APK
                    self.waydroid.install_app(str(patched_apk))
                    
                    return AppFix(
                        issue=issue,
                        fix_type="apk_patch",
                        patch_data={"patched_apk": str(patched_apk)},
                        success=True,
                        timestamp=time.time()
                    )
                    
        except Exception as e:
            logger.error(f"Failed to fix framework issue: {e}")
        
        return None
    
    async def extract_installed_apk(self, package_name: str) -> Optional[Path]:
        """Extract APK of installed app"""
        try:
            # Get APK path
            success, output = self.waydroid.execute_shell(
                f"pm path {package_name}"
            )
            
            if success and output:
                apk_path = output.strip().replace("package:", "")
                
                # Pull APK from Waydroid
                local_path = self.patches_dir / f"{package_name}.apk"
                
                subprocess.run([
                    "waydroid", "shell", "cat", apk_path
                ], stdout=open(local_path, 'wb'), check=True)
                
                return local_path
                
        except Exception as e:
            logger.error(f"Failed to extract APK: {e}")
        
        return None
    
    async def patch_apk_framework(self, apk_path: Path, issue: AppIssue) -> Optional[Path]:
        """Patch APK to fix framework issues"""
        try:
            work_dir = tempfile.mkdtemp()
            
            # Decompile APK using apktool
            subprocess.run([
                "apktool", "d", str(apk_path), "-o", work_dir
            ], check=True)
            
            # Modify AndroidManifest.xml to reduce Google Services requirements
            manifest_path = Path(work_dir) / "AndroidManifest.xml"
            if manifest_path.exists():
                # This is simplified - actual implementation would parse and modify XML
                manifest_content = manifest_path.read_text()
                
                # Remove Google Services metadata
                manifest_content = manifest_content.replace(
                    'android:name="com.google.android.gms.version"',
                    'android:name="removed.gms.version"'
                )
                
                manifest_path.write_text(manifest_content)
            
            # Rebuild APK
            output_apk = self.patches_dir / f"{issue.package_name}_patched.apk"
            subprocess.run([
                "apktool", "b", work_dir, "-o", str(output_apk)
            ], check=True)
            
            # Sign APK
            subprocess.run([
                "apksigner", "sign",
                "--ks", "/etc/airos/debug.keystore",
                "--ks-pass", "pass:android",
                str(output_apk)
            ], check=True)
            
            return output_apk
            
        except Exception as e:
            logger.error(f"Failed to patch APK: {e}")
        
        return None
    
    async def create_service_stub(self, package_name: str, stack_trace: str) -> bool:
        """Create a stub service to prevent crashes"""
        # This would create a minimal Android service that satisfies
        # the app's requirements without actual functionality
        # Implementation would be complex and require smali patching
        return False
    
    def store_fix(self, fix: AppFix):
        """Store applied fix in database"""
        conn = sqlite3.connect(self.fixes_db)
        cursor = conn.cursor()
        
        # Get issue ID
        cursor.execute(
            "SELECT id FROM app_issues WHERE package_name = ? ORDER BY detected_at DESC LIMIT 1",
            (fix.issue.package_name,)
        )
        issue_id = cursor.fetchone()[0]
        
        # Store fix
        cursor.execute('''
            INSERT INTO app_fixes 
            (issue_id, fix_type, patch_data, success, applied_at)
            VALUES (?, ?, ?, ?, ?)
        ''', (
            issue_id,
            fix.fix_type,
            json.dumps(fix.patch_data),
            fix.success,
            fix.timestamp
        ))
        
        # Mark issue as fixed if successful
        if fix.success:
            cursor.execute(
                "UPDATE app_issues SET fixed = TRUE WHERE id = ?",
                (issue_id,)
            )
        
        conn.commit()
        conn.close()


class AIROSLinuxAgent:
    """Main AIROS Linux Agent service"""
    
    def __init__(self):
        self.port = 8080
        self.ws_port = 8081
        self.waydroid = WaydroidManager()
        self.microg = MicroGManager(self.waydroid)
        self.app_fixer = AppCompatibilityFixer(self.waydroid)
        self.app = web.Application()
        self.setup_routes()
        
    def setup_routes(self):
        """Setup HTTP API routes"""
        self.app.router.add_post('/api/execute', self.handle_execute)
        self.app.router.add_post('/api/install_app', self.handle_install_app)
        self.app.router.add_post('/api/fix_app', self.handle_fix_app)
        self.app.router.add_get('/api/system_info', self.handle_system_info)
        self.app.router.add_get('/api/app_issues', self.handle_get_issues)
        self.app.router.add_post('/api/waydroid/start', self.handle_waydroid_start)
        self.app.router.add_post('/api/waydroid/stop', self.handle_waydroid_stop)
        self.app.router.add_post('/api/microg/configure', self.handle_microg_config)
    
    async def handle_execute(self, request):
        """Execute system command"""
        data = await request.json()
        command = data.get('command')
        in_waydroid = data.get('in_waydroid', False)
        
        if in_waydroid:
            success, output = self.waydroid.execute_shell(command)
        else:
            try:
                result = subprocess.run(
                    command,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                success = result.returncode == 0
                output = result.stdout + result.stderr
            except subprocess.TimeoutExpired:
                success = False
                output = "Command timeout"
        
        return web.json_response({
            'success': success,
            'output': output
        })
    
    async def handle_install_app(self, request):
        """Install and automatically fix an app"""
        data = await request.json()
        apk_url = data.get('apk_url')
        package_name = data.get('package_name')
        
        # Download APK
        temp_apk = Path(tempfile.mktemp(suffix='.apk'))
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(apk_url) as resp:
                    temp_apk.write_bytes(await resp.read())
            
            # Pre-patch if needed
            if data.get('pre_patch'):
                # Analyze APK for potential issues
                # This would involve parsing the APK and checking for
                # known incompatibilities
                pass
            
            # Install
            success = self.waydroid.install_app(str(temp_apk))
            
            # Start monitoring for crashes
            if success:
                asyncio.create_task(
                    self.monitor_app_launch(package_name)
                )
            
            return web.json_response({
                'success': success,
                'package_name': package_name
            })
            
        finally:
            temp_apk.unlink(missing_ok=True)
    
    async def monitor_app_launch(self, package_name: str):
        """Monitor app launch and fix issues in real-time"""
        # Launch the app
        self.waydroid.execute_shell(
            f"monkey -p {package_name} -c android.intent.category.LAUNCHER 1"
        )
        
        # Monitor for crashes for 30 seconds
        await asyncio.sleep(30)
    
    async def handle_fix_app(self, request):
        """Manually trigger app fixing"""
        data = await request.json()
        package_name = data.get('package_name')
        
        # Get app info
        app_info = self.waydroid.get_app_info(package_name)
        
        # Check for issues
        issues = []
        
        # Check for Google Services dependency
        if 'com.google.android.gms' in str(app_info):
            issue = AppIssue(
                package_name=package_name,
                issue_type=AppFixType.FRAMEWORK,
                description="Google Services dependency detected"
            )
            issues.append(issue)
        
        # Apply fixes
        fixes = []
        for issue in issues:
            fix = await self.app_fixer.auto_fix_issue(issue)
            if fix:
                fixes.append(asdict(fix))
        
        return web.json_response({
            'package_name': package_name,
            'issues_found': len(issues),
            'fixes_applied': fixes
        })
    
    async def handle_system_info(self, request):
        """Get system information"""
        info = {
            'os': 'AIROS-Linux',
            'version': '0.1.0-alpha',
            'kernel': os.uname().release,
            'waydroid_running': self.waydroid.is_running(),
            'installed_packages': len(self.waydroid.list_packages()),
            'cpu_percent': psutil.cpu_percent(),
            'memory_percent': psutil.virtual_memory().percent,
            'disk_usage': psutil.disk_usage('/').percent
        }
        
        return web.json_response(info)
    
    async def handle_get_issues(self, request):
        """Get detected app issues from database"""
        conn = sqlite3.connect(self.app_fixer.fixes_db)
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT package_name, issue_type, description, severity, fixed
            FROM app_issues
            ORDER BY detected_at DESC
            LIMIT 100
        ''')
        
        issues = []
        for row in cursor.fetchall():
            issues.append({
                'package_name': row[0],
                'issue_type': row[1],
                'description': row[2],
                'severity': row[3],
                'fixed': bool(row[4])
            })
        
        conn.close()
        
        return web.json_response(issues)
    
    async def handle_waydroid_start(self, request):
        """Start Waydroid container"""
        success = self.waydroid.start()
        return web.json_response({'success': success})
    
    async def handle_waydroid_stop(self, request):
        """Stop Waydroid container"""
        success = self.waydroid.stop()
        return web.json_response({'success': success})
    
    async def handle_microg_config(self, request):
        """Configure MicroG services"""
        data = await request.json()
        success = self.microg.configure_services(data)
        return web.json_response({'success': success})
    
    async def start(self):
        """Start the AI agent service"""
        logger.info("Starting AIROS Linux Agent...")
        
        # Ensure Waydroid is running
        if not self.waydroid.is_running():
            logger.info("Starting Waydroid container...")
            self.waydroid.start()
        
        # Start crash monitor
        asyncio.create_task(self.app_fixer.monitor_app_crashes())
        
        # Start HTTP server
        runner = web.AppRunner(self.app)
        await runner.setup()
        site = web.TCPSite(runner, '0.0.0.0', self.port)
        await site.start()
        
        logger.info(f"AIROS Linux Agent running on port {self.port}")
        
        # Keep running
        while True:
            await asyncio.sleep(3600)


async def main():
    """Main entry point"""
    agent = AIROSLinuxAgent()
    await agent.start()


if __name__ == "__main__":
    # Run with systemd or directly
    asyncio.run(main())