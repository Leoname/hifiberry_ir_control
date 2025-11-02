#!/usr/bin/env python3
"""
IR Remote Control for HiFiBerry OS
Sends infrared commands to control audio receivers
Compatible with minimal Buildroot-based HiFiBerry OS
"""

import os
import sys
import argparse
import subprocess
import glob

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

def find_ir_device():
    """Find the IR transmitter device"""
    devices = glob.glob("/dev/lirc*")
    if devices:
        return devices[0]
    return None

def check_ir_ctl():
    """Check if ir-ctl command is available"""
    try:
        subprocess.run(["ir-ctl", "--version"], 
                      stdout=subprocess.PIPE, 
                      stderr=subprocess.PIPE, 
                      check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def send_ir_command(command, device=None):
    """
    Send an IR command using ir-ctl
    
    Args:
        command: Command name from COMMANDS_TO_CODE_MAPPING
        device: IR device path (auto-detected if None)
    
    Returns:
        True if successful, False otherwise
    """
    if command not in COMMANDS_TO_CODE_MAPPING:
        print(f"Error: Command '{command}' not available", file=sys.stderr)
        print(f"Available commands: {', '.join(COMMANDS_TO_CODE_MAPPING.keys())}")
        return False
    
    # Check if ir-ctl is available
    if not check_ir_ctl():
        print("Error: ir-ctl command not found", file=sys.stderr)
        print("Please ensure IR tools are installed on HiFiBerry OS", file=sys.stderr)
        return False
    
    # Find IR device if not specified
    if device is None:
        device = find_ir_device()
        if device is None:
            print("Error: No IR device found at /dev/lirc*", file=sys.stderr)
            print("", file=sys.stderr)
            print("To enable IR transmitter:", file=sys.stderr)
            print("  1. Add to /boot/config.txt:", file=sys.stderr)
            print("     dtoverlay=gpio-ir-tx,gpio_pin=18", file=sys.stderr)
            print("  2. Reboot the system", file=sys.stderr)
            return False
    
    # Build ir-ctl command
    ir_code = COMMANDS_TO_CODE_MAPPING[command]
    cmd = ["ir-ctl", "-d", device, "-S", f"necx:{ir_code}"]
    
    try:
        result = subprocess.run(cmd, 
                              stdout=subprocess.PIPE, 
                              stderr=subprocess.PIPE, 
                              check=True)
        print(f"✓ Transmitted '{command}' signal (code: {ir_code})")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to transmit IR signal", file=sys.stderr)
        print(f"Command: {' '.join(cmd)}", file=sys.stderr)
        print(f"Error output: {e.stderr.decode()}", file=sys.stderr)
        return False

def main():
    parser = argparse.ArgumentParser(
        prog='RemoteControl',
        description='Send IR commands to control audio receiver'
    )
    
    parser.add_argument('-c', '--command', 
                       required=True,
                       help='Command to send')
    parser.add_argument('-d', '--device',
                       help='IR device (default: auto-detect)')
    parser.add_argument('-l', '--list',
                       action='store_true',
                       help='List available commands')
    
    args = parser.parse_args()
    
    # List commands if requested
    if args.list:
        print("Available commands:")
        for cmd, code in sorted(COMMANDS_TO_CODE_MAPPING.items()):
            print(f"  {cmd:20s} -> {code}")
        return 0
    
    # Send command
    success = send_ir_command(args.command, args.device)
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())



