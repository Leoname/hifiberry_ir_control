#!/usr/bin/env python3
"""
IR Remote Controller for HiFiBerry audiocontrol2
Integrates IR remote control into the official HiFiBerry API

This controller extends audiocontrol2 to provide IR remote control capabilities
through the standard HiFiBerry API endpoints.
"""

import logging
import subprocess
import glob
from typing import Dict, Any, Optional

# Command to IR code mapping (NEC Extended protocol)
COMMANDS_TO_CODE_MAPPING = {
    "power": "0xd26d04",
    "input_tuner": "0xd26d0b",
    "input_phono": "0xd26d0a",
    "input_cd": "0xd26d09",
    "input_direct": "0xd26d44",
    "input_video1": "0xd26d0f",
    "input_video2": "0xd26d0e",
    "input_tape1": "0xd26d08",
    "input_tape2": "0xd26d07",
    "mute": "0xd26d05",
    "volume_up": "0xd26d02",
    "volume_down": "0xd26d03"
}


class IRRemoteController:
    """Controller for IR remote control functionality"""
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the IR Remote Controller
        
        Args:
            config: Configuration dictionary (optional)
        """
        self.config = config or {}
        self.logger = logging.getLogger(__name__)
        self.ir_device = self._find_ir_device()
        self.last_command = None
        self.last_status = "Ready"
        
        if self.ir_device:
            self.logger.info(f"IR Remote Controller initialized with device: {self.ir_device}")
        else:
            self.logger.warning("IR device not found at initialization")
    
    def _find_ir_device(self) -> Optional[str]:
        """Find the IR transmitter device"""
        devices = glob.glob("/dev/lirc*")
        if devices:
            return devices[0]
        return None
    
    def _check_ir_ctl(self) -> bool:
        """Check if ir-ctl command is available"""
        try:
            subprocess.run(
                ["ir-ctl", "--version"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=True,
                timeout=2
            )
            return True
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            return False
    
    def send_command(self, command: str) -> Dict[str, Any]:
        """
        Send an IR command
        
        Args:
            command: Command name from COMMANDS_TO_CODE_MAPPING
        
        Returns:
            Dictionary with result status and message
        """
        # Validate command
        if command not in COMMANDS_TO_CODE_MAPPING:
            self.logger.error(f"Unknown command: {command}")
            return {
                "success": False,
                "error": f"Unknown command: {command}",
                "available_commands": list(COMMANDS_TO_CODE_MAPPING.keys())
            }
        
        # Check if ir-ctl is available
        if not self._check_ir_ctl():
            self.logger.error("ir-ctl command not found")
            return {
                "success": False,
                "error": "ir-ctl command not available"
            }
        
        # Find IR device if not already found
        if not self.ir_device:
            self.ir_device = self._find_ir_device()
            if not self.ir_device:
                self.logger.error("No IR device found")
                return {
                    "success": False,
                    "error": "No IR device found at /dev/lirc*"
                }
        
        # Send the IR command
        ir_code = COMMANDS_TO_CODE_MAPPING[command]
        cmd = ["ir-ctl", "-d", self.ir_device, "-S", f"necx:{ir_code}"]
        
        try:
            result = subprocess.run(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=True,
                timeout=5
            )
            
            self.last_command = command
            self.last_status = "Success"
            
            self.logger.info(f"Successfully sent IR command: {command} ({ir_code})")
            
            return {
                "success": True,
                "command": command,
                "ir_code": ir_code,
                "message": f"Transmitted '{command}' signal"
            }
            
        except subprocess.CalledProcessError as e:
            self.last_status = "Failed"
            self.logger.error(f"Failed to send IR command: {e.stderr.decode()}")
            return {
                "success": False,
                "error": f"Transmission failed: {e.stderr.decode().strip()}"
            }
        except subprocess.TimeoutExpired:
            self.last_status = "Timeout"
            self.logger.error("IR command timeout")
            return {
                "success": False,
                "error": "Command timeout"
            }
    
    def get_status(self) -> Dict[str, Any]:
        """
        Get current controller status
        
        Returns:
            Dictionary with controller status
        """
        return {
            "ir_device": self.ir_device,
            "last_command": self.last_command,
            "last_status": self.last_status,
            "available": self.ir_device is not None,
            "commands_available": len(COMMANDS_TO_CODE_MAPPING)
        }
    
    def get_available_commands(self) -> Dict[str, str]:
        """
        Get list of available commands with descriptions
        
        Returns:
            Dictionary of command names and their IR codes
        """
        return COMMANDS_TO_CODE_MAPPING.copy()
    
    def volume_up(self) -> Dict[str, Any]:
        """Increase volume"""
        return self.send_command("volume_up")
    
    def volume_down(self) -> Dict[str, Any]:
        """Decrease volume"""
        return self.send_command("volume_down")
    
    def mute(self) -> Dict[str, Any]:
        """Toggle mute"""
        return self.send_command("mute")
    
    def power(self) -> Dict[str, Any]:
        """Toggle power"""
        return self.send_command("power")
    
    def set_input(self, input_name: str) -> Dict[str, Any]:
        """
        Switch to specific input
        
        Args:
            input_name: Input name (e.g., 'cd', 'phono', 'tuner')
        
        Returns:
            Result dictionary
        """
        command = f"input_{input_name}"
        if command in COMMANDS_TO_CODE_MAPPING:
            return self.send_command(command)
        else:
            return {
                "success": False,
                "error": f"Unknown input: {input_name}",
                "available_inputs": [
                    cmd.replace("input_", "") 
                    for cmd in COMMANDS_TO_CODE_MAPPING.keys() 
                    if cmd.startswith("input_")
                ]
            }


# Factory function for audiocontrol2 integration
def create_controller(config: Optional[Dict[str, Any]] = None) -> IRRemoteController:
    """
    Factory function to create IR Remote Controller instance
    This is called by audiocontrol2 to instantiate the controller
    
    Args:
        config: Configuration dictionary from audiocontrol2
    
    Returns:
        IRRemoteController instance
    """
    return IRRemoteController(config)


# For standalone testing
if __name__ == "__main__":
    # Set up logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # Create controller
    controller = IRRemoteController()
    
    # Test status
    print("Controller Status:")
    print(controller.get_status())
    print()
    
    # Test available commands
    print("Available Commands:")
    for cmd, code in controller.get_available_commands().items():
        print(f"  {cmd}: {code}")
    print()
    
    # Test sending a command
    print("Testing power command...")
    result = controller.send_command("power")
    print(result)

