# Installation Guide - IR Remote Control for HiFiBerry OS

This guide provides detailed installation instructions for the IR Remote Control plugin.

## Prerequisites

Before installing, ensure you have:

* HiFiBerry OS running on Raspberry Pi
* Python 3 (pre-installed on HiFiBerry OS)
* `ir-ctl` command (included in HiFiBerry OS)
* IR LED connected to GPIO pin (see Hardware Setup below)
* Root access to the device

## Hardware Setup

### IR LED Circuit

Connect an IR LED to your Raspberry Pi with a current-limiting resistor:

```
IR LED Circuit:
  
  Anode (+) ──[220Ω resistor]── GPIO 17 (Physical Pin 11)
  Cathode (-)───────────────── GND (Physical Pin 9 or 14)
```

**Recommended Components:**
- IR LED (940nm wavelength)
- 220Ω resistor (current-limiting)
- Jumper wires

### GPIO Pin Selection

**⚠️ IMPORTANT: HiFiBerry DAC Compatibility**

If using a HiFiBerry DAC (DAC+, DAC2, DAC2 Pro, etc.), certain GPIO pins are reserved:

**SAFE pins for HiFiBerry DAC users:**
- **GPIO 17 (Pin 11)** - ⭐ **RECOMMENDED DEFAULT**
- GPIO 13 (Pin 33) - hardware PWM capable (if GPIO 12 not used by fan)
- GPIO 22 (Pin 15)
- GPIO 23 (Pin 16)
- GPIO 24 (Pin 18)
- GPIO 25 (Pin 22)
- GPIO 27 (Pin 13)

**⚠️ DO NOT USE (I2S Audio Conflict):**
- GPIO 18, 19, 20, 21 - Reserved for I2S audio interface
- **Will cause audio dropouts, system instability, or reboots!**

**⚠️ MAY ALREADY BE IN USE:**
- GPIO 12 - Often used by fan control plugins

See [`HIFIBERRY_DAC_COMPATIBILITY.md`](HIFIBERRY_DAC_COMPATIBILITY.md) for complete GPIO reference.

## Installation Methods

### Method 1: Direct Install from GitHub (Recommended)

```bash
# SSH into your HiFiBerry OS device
ssh root@<your-hifiberry-ip>

# Clone the repository
cd /tmp
git clone https://github.com/Leoname/hifiberry_ir_control.git
cd hifiberry_ir_control

# Run the installation script
chmod +x install.sh
./install.sh
```

### Method 2: One-Line Install

```bash
ssh root@<your-hifiberry-ip> "cd /tmp && git clone https://github.com/Leoname/hifiberry_ir_control.git && cd hifiberry_ir_control && chmod +x install.sh && ./install.sh"
```

Replace `<your-hifiberry-ip>` with your device's IP address or hostname (usually `hifiberry.local`).

### Method 3: Manual File Transfer

If git is not available on your device:

```bash
# On your computer - download and transfer files
wget https://github.com/Leoname/hifiberry_ir_control/archive/refs/heads/main.zip
unzip main.zip
scp -r hifiberry_ir_control-main root@<your-hifiberry-ip>:/tmp/hifiberry_ir_control

# SSH in and install
ssh root@<your-hifiberry-ip>
cd /tmp/hifiberry_ir_control
chmod +x install.sh
./install.sh
```

## What the Installer Does

The installation script will:

1. **Check for IR Transmitter**: Verifies `ir-ctl` is available
2. **Configure GPIO**: Sets up `gpio-ir-tx` overlay in `/boot/config.txt` (GPIO 17 by default)
3. **Install Core Files**: Copies scripts to `/opt/hifiberry/ir-remote-control/`
   - `remote_control.py` - IR transmission script
   - `ir_api_server.py` - HTTP API server
4. **Install Beocreate Extension**: Copies UI files to `/opt/beocreate/beo-extensions/ir-remote-control/`
   - `index.js` - Extension registration
   - `menu.html` - Web interface
   - `ir-remote-client.js` - Client-side JavaScript
   - `package.json` - Extension metadata
5. **Set Up Service**: Installs and starts API service (systemd or init.d)
6. **Restart Beocreate**: Reloads web interface to show new extension

## First-Time Setup

If this is your **first time configuring IR transmitter on this device**, you need to reboot after installation:

```bash
# After running install.sh for the first time
reboot
```

The reboot is necessary for the kernel to load the `gpio-ir-tx` device tree overlay.

After reboot, verify the IR device exists:

```bash
ls -la /dev/lirc*
# Should show: /dev/lirc0
```

## Verifying Installation

### Check Service Status

**For systemd:**
```bash
systemctl status ir-api.service
```

**For init.d:**
```bash
/etc/init.d/ir-api status
```

### Test IR Transmission

```bash
# Send a power command
python3 /opt/hifiberry/ir-remote-control/remote_control.py -c power

# List available commands
python3 /opt/hifiberry/ir-remote-control/remote_control.py --list
```

### Test API Server

```bash
# Check API is responding
curl http://localhost:8089/api/status

# Should return JSON like:
# {"last_command": "None", "last_status": "Ready", "timestamp": 0}
```

### Check Web Interface

1. Open browser to `http://hifiberry.local` (or your device IP)
2. Navigate to extensions/sources menu
3. Look for "IR Remote Control" entry
4. Click to open the interface

## Customizing GPIO Pin

To use a different GPIO pin than the default GPIO 17:

### Before Installation

Edit `install.sh` before running it:

```bash
# Find this line (around line 20):
IR_GPIO_PIN=17

# Change to your desired pin:
IR_GPIO_PIN=22
```

### After Installation

Manually edit `/boot/config.txt`:

```bash
# Remount /boot as read-write
mount -o remount,rw /boot

# Edit the config file
nano /boot/config.txt

# Find the line:
# dtoverlay=gpio-ir-tx,gpio_pin=17

# Change to your desired pin:
# dtoverlay=gpio-ir-tx,gpio_pin=22

# Save and exit (Ctrl+X, Y, Enter)

# Remount /boot as read-only
mount -o remount,ro /boot

# Reboot for changes to take effect
reboot
```

## Customizing IR Codes

The default IR codes are for NEC Extended protocol. To use different codes:

1. **Edit `/opt/hifiberry/ir-remote-control/remote_control.py`:**

```python
COMMANDS_TO_CODE_MAPPING = {
    "power": "0xYOUR_CODE_HERE",
    "mute": "0xYOUR_CODE_HERE",
    "volume_up": "0xYOUR_CODE_HERE",
    "volume_down": "0xYOUR_CODE_HERE",
    # ... etc
}
```

2. **Restart the API service:**

```bash
# systemd
systemctl restart ir-api.service

# or init.d
/etc/init.d/ir-api restart
```

### Capturing IR Codes from Your Remote

If you have an IR receiver, you can capture codes from your existing remote:

```bash
# Set up IR receiver on GPIO 23 (requires reboot)
mount -o remount,rw /boot
echo "dtoverlay=gpio-ir,gpio_pin=23" >> /boot/config.txt
mount -o remount,ro /boot
reboot

# After reboot, capture codes
ir-ctl -d /dev/lirc1 --receive=captured.txt
# Press buttons on your original remote

# View captured codes
cat captured.txt
```

## Troubleshooting Installation

### Issue: `/dev/lirc0` not found after reboot

**Solution:**
```bash
# Check if overlay is in config
grep gpio-ir-tx /boot/config.txt

# Check kernel messages
dmesg | grep -i "gpio-ir\|lirc"

# Verify GPIO pin is not in use
cat /sys/kernel/debug/gpio
```

### Issue: Service fails to start

**Solution:**
```bash
# Check service logs
journalctl -u ir-api.service -n 50

# Or for init.d
tail -f /var/log/ir-api.log

# Test script manually
python3 /opt/hifiberry/ir-remote-control/ir_api_server.py
```

### Issue: Web interface not showing extension

**Solution:**
```bash
# Verify files are installed
ls -la /opt/beocreate/beo-extensions/ir-remote-control/

# Check Beocreate logs
journalctl -u beocreate2 -n 50 | grep -i extension

# Restart Beocreate
systemctl restart beocreate2
```

### Issue: Port 8089 already in use

**Solution:**
```bash
# Check what's using the port
netstat -tuln | grep 8089

# Kill the conflicting process or edit ir_api_server.py to use different port
# Change API_PORT = 8089 to another port number
```

For more troubleshooting help, see [`DEBUG.md`](DEBUG.md).

## Manual Installation Steps

If the automated installer doesn't work, follow these manual steps:

### 1. Configure IR Transmitter

```bash
mount -o remount,rw /boot
echo "dtoverlay=gpio-ir-tx,gpio_pin=17" >> /boot/config.txt
mount -o remount,ro /boot
reboot
```

### 2. Create Directory and Copy Files

```bash
mkdir -p /opt/hifiberry/ir-remote-control
cd /tmp/hifiberry_ir_control
cp remote_control.py /opt/hifiberry/ir-remote-control/
cp ir_api_server.py /opt/hifiberry/ir-remote-control/
chmod +x /opt/hifiberry/ir-remote-control/*.py
```

### 3. Install Beocreate Extension

```bash
mkdir -p /opt/beocreate/beo-extensions/ir-remote-control
cd /tmp/hifiberry_ir_control/beocreate/beo-extensions/ir-remote-control
cp index.js menu.html ir-remote-client.js package.json /opt/beocreate/beo-extensions/ir-remote-control/
```

### 4. Install and Start Service

**For systemd:**
```bash
cp ir-api.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable ir-api.service
systemctl start ir-api.service
```

**For init.d:**
```bash
cp ir-api-busybox.init /etc/init.d/ir-api
chmod +x /etc/init.d/ir-api
/etc/init.d/ir-api enable
/etc/init.d/ir-api start
```

### 5. Restart Beocreate

```bash
systemctl restart beocreate2
# or
/etc/init.d/beocreate2 restart
```

## Uninstallation

To remove the plugin:

```bash
cd /tmp/hifiberry_ir_control
chmod +x uninstall.sh
./uninstall.sh
```

Or with auto-confirm:
```bash
./uninstall.sh -y
```

The uninstaller will:
- Stop and remove services
- Delete all installed files
- Remove Beocreate extension
- Restart Beocreate

**Note:** The IR transmitter overlay in `/boot/config.txt` is NOT removed automatically. Remove it manually if needed:

```bash
mount -o remount,rw /boot
sed -i '/dtoverlay=gpio-ir-tx/d' /boot/config.txt
mount -o remount,ro /boot
reboot
```

## Advanced: audiocontrol2 Integration

For advanced users, you can integrate IR commands into the official HiFiBerry audiocontrol2 API. See [`audiocontrol2_integration/README_AUDIOCONTROL2.md`](audiocontrol2_integration/README_AUDIOCONTROL2.md) for details.

Both the standalone API (port 8089) and audiocontrol2 integration (port 81) can run simultaneously.

## Next Steps

After successful installation:

1. **Access Web Interface**: Navigate to IR Remote Control in your Beocreate UI
2. **Test Commands**: Try the power button to verify IR transmission
3. **Check LED**: Use phone camera to see IR LED flash when sending commands
4. **Customize Codes**: If needed, update IR codes for your specific receiver

For detailed usage instructions, see [`README.md`](README.md).

For troubleshooting, see [`DEBUG.md`](DEBUG.md).

