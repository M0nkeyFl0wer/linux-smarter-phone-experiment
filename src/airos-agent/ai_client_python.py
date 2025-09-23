#!/usr/bin/env python3
"""
AIROS Client - AI Agent Connection Library
Provides high-level interface for AI agents to interact with AIROS Android ROM
"""

import json
import time
import threading
import logging
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass
from enum import Enum

import requests
import websocket
from websocket import WebSocketApp

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class CommandType(Enum):
    """Types of commands that can be executed"""
    SHELL = "shell"
    SYSTEM = "system"
    APP = "app"
    SERVICE = "service"
    DEBUG = "debug"


@dataclass
class DeviceInfo:
    """Device information structure"""
    device: str
    model: str
    android_version: str
    sdk_version: int
    airos_version: str
    uptime: int
    total_memory: int
    free_memory: int


@dataclass
class CommandResult:
    """Result from command execution"""
    success: bool
    output: str
    exit_code: int
    error: Optional[str] = None
    execution_time: float = 0.0


class AIROSClient:
    """Main client for connecting to AIROS-enabled Android devices"""
    
    def __init__(self, device_ip: str, auth_token: str, port: int = 8080, ws_port: int = 8081):
        """
        Initialize AIROS client
        
        Args:
            device_ip: IP address of the Android device
            auth_token: Authentication token from the device
            port: HTTP API port (default 8080)
            ws_port: WebSocket port for real-time monitoring (default 8081)
        """
        self.device_ip = device_ip
        self.auth_token = auth_token
        self.port = port
        self.ws_port = ws_port
        
        self.base_url = f"http://{device_ip}:{port}/api"
        self.ws_url = f"ws://{device_ip}:{ws_port}"
        
        self.session = requests.Session()
        self.session.headers.update({
            "Authorization": f"Bearer {auth_token}",
            "Content-Type": "application/json"
        })
        
        self.ws_app: Optional[WebSocketApp] = None
        self.ws_thread: Optional[threading.Thread] = None
        self.event_handlers: Dict[str, List[Callable]] = {}
        
        # Verify connection
        self._verify_connection()
    
    def _verify_connection(self):
        """Verify connection to the device"""
        try:
            info = self.get_system_info()
            logger.info(f"Connected to {info.model} running AIROS {info.airos_version}")
        except Exception as e:
            raise ConnectionError(f"Failed to connect to device: {e}")
    
    def _make_request(self, endpoint: str, method: str = "GET", 
                     data: Optional[Dict] = None) -> Dict:
        """Make HTTP request to the device"""
        url = f"{self.base_url}/{endpoint}"
        
        try:
            if method == "GET":
                response = self.session.get(url)
            elif method == "POST":
                response = self.session.post(url, json=data or {})
            elif method == "PUT":
                response = self.session.put(url, json=data or {})
            elif method == "DELETE":
                response = self.session.delete(url)
            else:
                raise ValueError(f"Unsupported method: {method}")
            
            response.raise_for_status()
            return response.json()
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Request failed: {e}")
            raise
    
    # System Information Methods
    
    def get_system_info(self) -> DeviceInfo:
        """Get device system information"""
        data = self._make_request("system/info")
        return DeviceInfo(
            device=data["device"],
            model=data["model"],
            android_version=data["androidVersion"],
            sdk_version=data["sdkVersion"],
            airos_version=data["airosVersion"],
            uptime=data["uptime"],
            total_memory=data["totalMemory"],
            free_memory=data["freeMemory"]
        )
    
    # Command Execution Methods
    
    def execute_command(self, command: str, timeout: int = 5000) -> CommandResult:
        """
        Execute a shell command on the device
        
        Args:
            command: Shell command to execute
            timeout: Timeout in milliseconds
            
        Returns:
            CommandResult with output and status
        """
        start_time = time.time()
        
        data = self._make_request("execute", "POST", {
            "command": command,
            "timeout": timeout
        })
        
        execution_time = time.time() - start_time
        
        return CommandResult(
            success="error" not in data,
            output=data.get("output", ""),
            exit_code=data.get("exitCode", -1),
            error=data.get("error"),
            execution_time=execution_time
        )
    
    def execute_as_root(self, command: str, timeout: int = 5000) -> CommandResult:
        """Execute command with root privileges"""
        return self.execute_command(f"su -c '{command}'", timeout)
    
    # Code Injection Methods
    
    def inject_code(self, target_class: str, method_name: str, 
                   code: str, language: str = "java") -> bool:
        """
        Inject code into a running system component
        
        Args:
            target_class: Fully qualified class name
            method_name: Method to replace/modify
            code: New code to inject
            language: Programming language (java or smali)
            
        Returns:
            Success status
        """
        data = self._make_request("inject", "POST", {
            "targetClass": target_class,
            "methodName": method_name,
            "code": code,
            "language": language
        })
        
        return data.get("success", False)
    
    # Snapshot and Rollback Methods
    
    def create_snapshot(self, name: str = "manual") -> str:
        """
        Create a system snapshot for rollback
        
        Args:
            name: Snapshot name/description
            
        Returns:
            Snapshot ID
        """
        data = self._make_request("snapshot", "POST", {"name": name})
        
        if data.get("success"):
            snapshot_id = data["snapshotId"]
            logger.info(f"Created snapshot: {snapshot_id}")
            return snapshot_id
        else:
            raise Exception("Failed to create snapshot")
    
    def rollback(self, snapshot_id: str) -> bool:
        """
        Rollback system to a previous snapshot
        
        Args:
            snapshot_id: ID of snapshot to restore
            
        Returns:
            Success status
        """
        data = self._make_request("rollback", "POST", {"snapshotId": snapshot_id})
        
        success = data.get("success", False)
        if success:
            logger.info(f"Successfully rolled back to: {snapshot_id}")
        else:
            logger.error(f"Rollback failed for: {snapshot_id}")
        
        return success
    
    # Application Management Methods
    
    def list_apps(self) -> List[Dict]:
        """List all installed applications"""
        data = self._make_request("apps/list")
        return data.get("apps", [])
    
    def modify_app(self, package_name: str, modification: str) -> bool:
        """
        Modify an installed application
        
        Args:
            package_name: Package name of the app
            modification: Modification to apply
            
        Returns:
            Success status
        """
        data = self._make_request("apps/modify", "POST", {
            "packageName": package_name,
            "modification": modification
        })
        
        return data.get("success", False)
    
    def install_app(self, apk_path: str) -> bool:
        """Install an APK file"""
        result = self.execute_command(f"pm install -r {apk_path}")
        return result.success
    
    def uninstall_app(self, package_name: str) -> bool:
        """Uninstall an application"""
        result = self.execute_command(f"pm uninstall {package_name}")
        return result.success
    
    # Service Management Methods
    
    def start_service(self, service_name: str) -> bool:
        """Start an Android service"""
        result = self.execute_command(f"am startservice {service_name}")
        return result.success
    
    def stop_service(self, service_name: str) -> bool:
        """Stop an Android service"""
        result = self.execute_command(f"am stopservice {service_name}")
        return result.success
    
    def restart_service(self, service_name: str) -> bool:
        """Restart an Android service"""
        self.stop_service(service_name)
        time.sleep(1)
        return self.start_service(service_name)
    
    # Debug Methods
    
    def get_logs(self, lines: int = 100, filter: str = "AIROS") -> List[str]:
        """
        Get system logs
        
        Args:
            lines: Number of log lines to retrieve
            filter: Log tag filter
            
        Returns:
            List of log lines
        """
        data = self._make_request("debug/logs", "POST", {
            "lines": lines,
            "filter": filter
        })
        
        return data.get("logs", [])
    
    def dump_system_service(self, service: str) -> str:
        """Dump information from a system service"""
        result = self.execute_command(f"dumpsys {service}")
        return result.output
    
    # WebSocket Real-time Monitoring
    
    def start_monitoring(self, on_message: Optional[Callable] = None,
                        on_error: Optional[Callable] = None):
        """
        Start WebSocket connection for real-time monitoring
        
        Args:
            on_message: Callback for incoming messages
            on_error: Callback for errors
        """
        def _on_message(ws, message):
            try:
                data = json.loads(message)
                logger.debug(f"WebSocket message: {data}")
                
                if on_message:
                    on_message(data)
                
                # Dispatch to event handlers
                event_type = data.get("eventType")
                if event_type in self.event_handlers:
                    for handler in self.event_handlers[event_type]:
                        handler(data)
                        
            except json.JSONDecodeError:
                logger.error(f"Invalid JSON message: {message}")
        
        def _on_error(ws, error):
            logger.error(f"WebSocket error: {error}")
            if on_error:
                on_error(error)
        
        def _on_open(ws):
            logger.info("WebSocket connection opened")
            # Send authentication
            ws.send(json.dumps({
                "action": "authenticate",
                "token": self.auth_token
            }))
        
        def _on_close(ws):
            logger.info("WebSocket connection closed")
        
        self.ws_app = WebSocketApp(
            self.ws_url,
            on_message=_on_message,
            on_error=_on_error,
            on_open=_on_open,
            on_close=_on_close
        )
        
        self.ws_thread = threading.Thread(target=self.ws_app.run_forever)
        self.ws_thread.daemon = True
        self.ws_thread.start()
        
        logger.info("Started real-time monitoring")
    
    def stop_monitoring(self):
        """Stop WebSocket monitoring"""
        if self.ws_app:
            self.ws_app.close()
            self.ws_thread.join(timeout=5)
            logger.info("Stopped real-time monitoring")
    
    def subscribe_to_event(self, event_type: str, handler: Callable):
        """
        Subscribe to specific system events
        
        Args:
            event_type: Type of event to subscribe to
            handler: Callback function for the event
        """
        if event_type not in self.event_handlers:
            self.event_handlers[event_type] = []
        
        self.event_handlers[event_type].append(handler)
        
        # Send subscription request
        if self.ws_app:
            self.ws_app.send(json.dumps({
                "action": "subscribe",
                "eventType": event_type
            }))
    
    # High-level Helper Methods
    
    def safe_execute(self, operation: Callable, *args, **kwargs) -> Any:
        """
        Execute operation with automatic snapshot and rollback on failure
        
        Args:
            operation: Function to execute
            *args: Arguments for the operation
            **kwargs: Keyword arguments for the operation
            
        Returns:
            Result of the operation
        """
        # Create snapshot
        snapshot_id = self.create_snapshot(f"before_{operation.__name__}")
        
        try:
            # Execute operation
            result = operation(*args, **kwargs)
            
            # If successful, return result
            logger.info(f"Operation {operation.__name__} completed successfully")
            return result
            
        except Exception as e:
            # On failure, rollback
            logger.error(f"Operation failed: {e}")
            logger.info("Initiating rollback...")
            
            if self.rollback(snapshot_id):
                logger.info("System restored to previous state")
            else:
                logger.error("Rollback failed - manual intervention may be required")
            
            raise
    
    def run_experiment(self, name: str, setup: Callable, test: Callable, 
                       cleanup: Optional[Callable] = None) -> Dict:
        """
        Run a complete experiment with setup, test, and cleanup phases
        
        Args:
            name: Experiment name
            setup: Setup function
            test: Test function
            cleanup: Optional cleanup function
            
        Returns:
            Experiment results
        """
        logger.info(f"Starting experiment: {name}")
        
        results = {
            "name": name,
            "start_time": time.time(),
            "success": False,
            "error": None,
            "output": None
        }
        
        # Create snapshot before experiment
        snapshot_id = self.create_snapshot(f"experiment_{name}")
        
        try:
            # Setup phase
            logger.info("Running setup...")
            setup()
            
            # Test phase
            logger.info("Running test...")
            results["output"] = test()
            results["success"] = True
            
        except Exception as e:
            logger.error(f"Experiment failed: {e}")
            results["error"] = str(e)
            
            # Rollback on failure
            logger.info("Rolling back due to failure...")
            self.rollback(snapshot_id)
            
        finally:
            # Cleanup phase
            if cleanup:
                logger.info("Running cleanup...")
                try:
                    cleanup()
                except Exception as e:
                    logger.error(f"Cleanup failed: {e}")
            
            results["end_time"] = time.time()
            results["duration"] = results["end_time"] - results["start_time"]
        
        logger.info(f"Experiment completed: {results['success']}")
        return results
    
    def close(self):
        """Close all connections"""
        self.stop_monitoring()
        self.session.close()
        logger.info("Client closed")


# Example usage and experiments
if __name__ == "__main__":
    # Example: Connect to device and run experiments
    
    # Device connection details (would be obtained from device)
    DEVICE_IP = "192.168.1.100"
    AUTH_TOKEN = "your-auth-token-here"
    
    try:
        # Initialize client
        client = AIROSClient(DEVICE_IP, AUTH_TOKEN)
        
        # Get system info
        info = client.get_system_info()
        print(f"Connected to: {info.model}")
        print(f"Android Version: {info.android_version}")
        print(f"AIROS Version: {info.airos_version}")
        
        # Example 1: Execute simple command
        result = client.execute_command("getprop ro.build.version.release")
        print(f"Android version: {result.output.strip()}")
        
        # Example 2: Safe system modification
        def modify_system_property():
            return client.execute_as_root(
                "setprop debug.airos.test true"
            )
        
        client.safe_execute(modify_system_property)
        
        # Example 3: Monitor system events
        def handle_system_event(event):
            print(f"System event: {event}")
        
        client.start_monitoring()
        client.subscribe_to_event("system_change", handle_system_event)
        
        # Example 4: Run a complete experiment
        def experiment_setup():
            client.execute_command("mkdir -p /data/local/tmp/experiment")
        
        def experiment_test():
            # Test some system modification
            result = client.execute_command(
                "echo 'Test data' > /data/local/tmp/experiment/test.txt"
            )
            return result.output
        
        def experiment_cleanup():
            client.execute_command("rm -rf /data/local/tmp/experiment")
        
        results = client.run_experiment(
            "test_file_operations",
            experiment_setup,
            experiment_test,
            experiment_cleanup
        )
        
        print(f"Experiment results: {results}")
        
        # Example 5: Code injection (simplified example)
        java_code = """
        public class Injected {
            public static void modifiedMethod() {
                Log.d("AIROS", "Method successfully modified!");
            }
        }
        """
        
        success = client.inject_code(
            "com.android.systemui.SystemUIService",
            "onCreate",
            java_code,
            "java"
        )
        
        if success:
            print("Code injection successful!")
        
        # Keep monitoring for a while
        time.sleep(30)
        
    except Exception as e:
        logger.error(f"Error: {e}")
        
    finally:
        # Clean up
        client.close()