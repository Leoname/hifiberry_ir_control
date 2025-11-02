# IR Remote Control for HiFiBerry OS

A complete infrared remote control plugin for HiFiBerry OS that integrates seamlessly with the Beocreate web interface. Control your audio receiver directly from your HiFiBerry OS device!

![License](https://img.shields.io/badge/license-MIT-blue.svg)

## Features

* **Web Interface Integration**: Beautiful UI integrated into HiFiBerry OS Beocreate interface
* **Real-time Control**: Send IR commands with instant visual feedback
* **Multiple Input Sources**: Switch between Tuner, Phono, CD, Direct, Video, and Tape inputs
* **Volume Control**: Adjust volume and mute from the web interface
* **Command History**: View recent commands and their status
* **No External Dependencies**: Uses built-in `ir-ctl` and Python standard library
* **Auto-detection**: Automatically finds and configures IR transmitter device
* **HiFiBerry OS Compatible**: Designed for minimal Buildroot-based HiFiBerry OS

## Screenshots

The plugin adds an "IR Remote Control" extension to your HiFiBerry OS web interface with:
- Status display showing last command sent
- Power and mute controls
- Volume up/down buttons
- Input selection grid with 8 different inputs
- Real-time command log

## Requirements

* HiFiBerry OS running on Raspberry Pi
* Python 3 (pre-installed on HiFiBerry OS)
* `ir-ctl` command (v1.24.1+ recommended, included in HiFiBerry OS)
* IR LED connected to GPIO pin (default: GPIO 17)
* Root access to the system

## Hardware Setup

### IR LED Connection

Connect an IR LED to your Raspberry Pi:

```
IR LED (with current-limiting resistor):
  
  Anode (+) ──[220Ω resistor]── GPIO 17 (Physical Pin 11)
  Cathode (-)───────────────── GND (Physical Pin 9 or 14)
```

**⚠️ IMPORTANT: HiFiBerry DAC Compatibility**

If you're using a HiFiBerry DAC (DAC+, DAC2, etc.), **DO NOT use GPIO 18, 19, 20, or 21** for IR transmission! These pins are used by the I2S audio interface and will cause system instability, audio dropouts, or reboots.

**Safe pins for HiFiBerry DAC users:**
- GPIO 17 (default) ✅
- GPIO 12, 13 (hardware PWM) ✅
- GPIO 22, 23, 24, 25, 27 ✅

**Recommended Components:**
- IR LED (940nm wavelength recommended)
- 220Ω resistor (current-limiting)
- Jumper wires

**Alternative GPIO Pins:**
- GPIO 17 (Pin 11) - **recommended for HiFiBerry DACs** ⭐
- GPIO 12 (Pin 32) - hardware PWM capable
- GPIO 13 (Pin 33) - hardware PWM capable
- GPIO 22 (Pin 15)
- GPIO 23 (Pin 16)
- GPIO 24 (Pin 18)
- GPIO 25 (Pin 22)

**⚠️ WARNING - Do NOT use with HiFiBerry DACs:**
- GPIO 18, 19, 20, 21 - These are used by I2S audio and will cause conflicts/reboots!

## Installation

### Quick Install

1. **Clone or download this repository to your HiFiBerry OS device:**

```bash
# On HiFiBerry OS
cd /tmp
# Copy files from your computer or clone from repository
```

2. **Run the installation script:**

```bash
chmod +x install.sh
./install.sh
```

The installer will:
- Check and configure IR transmitter (GPIO 17 by default)
- Install scripts to `/opt/hifiberry/ir-remote-control/`
- Install Beocreate extension to `/opt/beocreate/beo-extensions/ir-remote-control/`
- Set up and start the API service
- Restart Beocreate to load the extension

3. **If this is first-time setup, you may need to reboot:**

```bash
reboot
```

After reboot, run `./install.sh` again to complete the installation.

### Finding Your GPIO Pin

If you're not sure which GPIO pin your IR LED is connected to, you can manually test pins using `ir-ctl`:

```bash
# Test GPIO 17
ir-ctl -d /dev/lirc0 -S necx:0xd26d04

# If device not found, configure it:
mount -o remount,rw /boot
echo "dtoverlay=gpio-ir-tx,gpio_pin=17" >> /boot/config.txt
mount -o remount,ro /boot
reboot
```

## Usage

### Web Interface

After installation, access the IR Remote Control through:

1. Open your HiFiBerry OS web interface (usually `http://hifiberry.local`)
2. Navigate to Extensions or Sources menu
3. Select "IR Remote Control"

The interface provides:
- **Power Button**: Toggle receiver power on/off
- **Mute Button**: Mute/unmute audio
- **Volume Controls**: Increase or decrease volume
- **Input Selection**: Switch between 8 different inputs
- **Status Display**: Shows last command and success/failure
- **Command Log**: Recent commands with timestamps

### Command Line

Test commands directly from the terminal:

```bash
# Send power command
python3 /opt/hifiberry/ir-remote-control/remote_control.py -c power

# List all available commands
python3 /opt/hifiberry/ir-remote-control/remote_control.py --list

# Increase volume
python3 /opt/hifiberry/ir-remote-control/remote_control.py -c volume_up

# Switch to CD input
python3 /opt/hifiberry/ir-remote-control/remote_control.py -c input_cd
```

### Available Commands

| Command | Description | IR Code |
|---------|-------------|---------|
| `power` | Power on/off | 0xd26d04 |
| `mute` | Mute audio | 0xd26d05 |
| `volume_up` | Increase volume | 0xd26d02 |
| `volume_down` | Decrease volume | 0xd26d03 |
| `input_tuner` | Switch to Tuner | 0xd26d0b |
| `input_phono` | Switch to Phono | 0xd26d0a |
| `input_cd` | Switch to CD | 0xd26d09 |
| `input_direct` | Switch to Direct | 0xd26d44 |
| `input_video1` | Switch to Video 1 | 0xd26d0f |
| `input_video2` | Switch to Video 2 | 0xd26d0e |
| `input_tape1` | Switch to Tape 1 | 0xd26d08 |
| `input_tape2` | Switch to Tape 2 | 0xd26d07 |

**Note:** These codes are for NEC Extended protocol. If your receiver uses different codes, you can capture them and update `remote_control.py`.

## Configuration

### Changing GPIO Pin

To use a different GPIO pin:

```bash
# Edit the install script before running
# Or manually edit /boot/config.txt:
mount -o remount,rw /boot
# Change the line: dtoverlay=gpio-ir-tx,gpio_pin=17
# to your desired pin number
mount -o remount,ro /boot
reboot
```


### Customizing IR Codes

If your receiver uses different IR codes:

1. **Capture codes from your existing remote:**

```bash
# Set up IR receiver (if available)
# Connect IR receiver to GPIO 23
mount -o remount,rw /boot
echo "dtoverlay=gpio-ir,gpio_pin=23" >> /boot/config.txt
mount -o remount,ro /boot
reboot

# Capture codes
ir-ctl -d /dev/lirc1 --receive=captured.txt
# Press buttons on your original remote
```

2. **Edit `remote_control.py`:**

```python
COMMANDS_TO_CODE_MAPPING = {
    "power": "0xYOURCODE",
    "volume_up": "0xYOURCODE",
    # ... update with your codes
}
```

3. **Restart the API service:**

```bash
systemctl restart ir-api.service
```

## API Options

### Option 1: Standalone API (Default)

The standalone API server runs on port 8089 and provides immediate access for the web interface.

### Option 2: audiocontrol2 Integration (Advanced)

For advanced users, you can integrate your IR commands into the **official HiFiBerry audiocontrol2 API** on port 81. This provides:
- Unified API with all HiFiBerry functions
- Better integration with home automation
- Standard HiFiBerry API conventions

See [`audiocontrol2_integration/README_AUDIOCONTROL2.md`](audiocontrol2_integration/README_AUDIOCONTROL2.md) for installation and usage.

**Both APIs can run simultaneously!**

## API Endpoints

The standalone API server runs on port 8089 and provides:

### GET /api/status
Returns current status:
```json
{
  "last_command": "power",
  "last_status": "Success",
  "timestamp": 1234567890
}
```

### GET /api/commands
Returns list of available commands:
```json
{
  "power": "Power on/off",
  "volume_up": "Increase volume",
  ...
}
```

### POST /api/send
Send an IR command:
```bash
curl -X POST http://localhost:8089/api/send \
  -H "Content-Type: application/json" \
  -d '{"command":"power"}'
```

Response:
```json
{
  "success": true,
  "command": "power",
  "output": "✓ Transmitted 'power' signal (code: 0xd26d04)"
}
```

## Troubleshooting

### IR Commands Not Working

1. **Check IR device exists:**
```bash
ls -la /dev/lirc*
# Should show /dev/lirc0
```

2. **Test IR transmission manually:**
```bash
ir-ctl -d /dev/lirc0 -S necx:0xd26d04
```

3. **Verify GPIO pin configuration:**
```bash
grep gpio-ir /boot/config.txt
# Should show: dtoverlay=gpio-ir-tx,gpio_pin=17
```

4. **Check LED with phone camera:**
   - Point phone camera at IR LED
   - Send a command
   - You should see LED flash purple/white on camera screen

5. **Check kernel messages:**
```bash
dmesg | grep -i "gpio-ir\|lirc"
```

### Service Not Running

**For systemd:**
```bash
# Check status
systemctl status ir-api.service

# View logs
journalctl -u ir-api.service -f

# Restart service
systemctl restart ir-api.service
```

**For init.d:**
```bash
# Check status
/etc/init.d/ir-api status

# View logs
tail -f /var/log/ir-api.log

# Restart service
/etc/init.d/ir-api restart
```

### Web Interface Not Showing

1. **Verify extension is installed:**
```bash
ls -la /opt/beocreate/beo-extensions/ir-remote-control/
```

2. **Restart Beocreate:**
```bash
systemctl restart beocreate2
# or
/etc/init.d/beocreate2 restart
```

3. **Check API server:**
```bash
curl http://localhost:8089/api/status
```

4. **Check browser console for errors** (F12 in most browsers)

### Wrong IR Codes

If commands are being sent but receiver doesn't respond:
- Your receiver may use a different IR protocol
- IR codes in `remote_control.py` may not match your receiver
- Use IR receiver to capture actual codes from your remote
- Verify receiver is in range and has clear line of sight

### Read-only Filesystem

HiFiBerry OS uses read-only filesystem. To modify config files:

```bash
mount -o remount,rw /boot
# Make changes
mount -o remount,ro /boot
```

The installation scripts handle this automatically.

## File Structure

```
/opt/hifiberry/ir-remote-control/
├── remote_control.py          # Main IR control script
├── ir_api_server.py          # API server for web interface
└── status.json               # Current status (created at runtime)

/opt/beocreate/beo-extensions/ir-remote-control/
├── index.js                  # Extension registration
├── ui.html                   # Web interface HTML
├── ui.js                     # Web interface JavaScript
└── ui.css                    # Styles

/etc/systemd/system/
└── ir-api.service           # Systemd service file

/etc/init.d/
└── ir-api                   # BusyBox init script
```

## Uninstallation

To completely remove the plugin:

```bash
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

**Note:** The IR transmitter overlay in `/boot/config.txt` is NOT removed automatically. Remove it manually if needed.

## Development

### Project Structure

This project follows the HiFiBerry OS Beocreate extension format:
- Python backend using `ir-ctl` for IR transmission
- HTTP API server for web interface communication
- Beocreate extension for UI integration
- systemd/init.d service management

### Contributing

Contributions welcome! Areas for improvement:
- Support for additional IR protocols
- Learning mode to capture remote codes
- Macro support (sequences of commands)
- Integration with HiFiBerry player events
- Additional receiver models/brands

## Technical Details

### IR Transmission

- **Protocol**: NEC Extended (32-bit)
- **Tool**: `ir-ctl` from v4l-utils package
- **Method**: Kernel-based IR transmission via `gpio-ir-tx` overlay
- **Frequency**: 38kHz carrier (standard for most IR remotes)

### Compatibility

- **Tested on**: HiFiBerry OS (Buildroot-based)
- **Python**: 3.x (standard library only)
- **Init Systems**: systemd and BusyBox init.d
- **Raspberry Pi**: All models with GPIO headers

## Credits

- Inspired by [hifiberry_fan_control](https://github.com/Leoname/hifiberry_fan_control)
- Built for HiFiBerry OS - minimal Linux distribution for audio
- Uses `ir-ctl` from v4l-utils package

## License

MIT License - see LICENSE file for details

## Support

For issues, questions, or contributions:
- Check the Troubleshooting section
- Review HiFiBerry OS documentation
- Test IR transmission with `ir-ctl` directly
- Verify hardware connections

## Acknowledgments

- HiFiBerry team for the excellent HiFiBerry OS
- Beocreate framework for extension support
- Linux kernel IR subsystem developers
- v4l-utils developers for `ir-ctl` tool

---

**Enjoy controlling your receiver from HiFiBerry OS! 🎵📡**

