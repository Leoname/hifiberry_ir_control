# IR Remote Control for HiFiBerry OS

This is an infrared remote control plugin for HiFiBerry OS that lets you control your audio receiver directly from the Beocreate web interface. Send IR commands to switch inputs, adjust volume, and control power without leaving your couch!

![IR Remote Control UI](https://img.shields.io/badge/HiFiBerry-IR%20Remote%20Control-orange)

## Features

* **Web Interface Integration**: Beautiful UI integrated into HiFiBerry OS Beocreate interface
* **Real-time Control**: Send IR commands with instant visual feedback
* **Multiple Input Sources**: Switch between Tuner, Phono, CD, Direct, Video, and Tape inputs
* **Volume & Power Control**: Adjust volume, mute, and power on/off from the web interface
* **Command History**: View recent commands and their status in real-time
* **No Dependencies**: Uses built-in `ir-ctl` and Python standard library only
* **HiFiBerry OS Compatible**: Designed specifically for the minimal Buildroot-based HiFiBerry OS

## Requirements

* HiFiBerry OS running on Raspberry Pi
* Python 3 (pre-installed)
* IR LED connected to GPIO pin (default: GPIO 17)
* Root access to the system

## Quick Install

```bash
ssh root@hifiberry.local "cd /tmp && git clone https://github.com/Leoname/hifiberry_ir_control.git && cd hifiberry_ir_control && chmod +x install.sh && ./install.sh"
```

Replace `hifiberry.local` with your device's hostname or IP address.

The installation script will:

* Configure IR transmitter (GPIO 17 by default)
* Install scripts to `/opt/hifiberry/ir-remote-control/`
* Add Beocreate extension to web interface
* Set up and start the API service
* Restart Beocreate to load the extension

**First-time setup requires a reboot:**
```bash
reboot
```

For detailed installation instructions, see [INSTALL.md](INSTALL.md).

## Hardware Setup

Connect an IR LED to your Raspberry Pi with a current-limiting resistor:

```
IR LED Circuit:
  
  Anode (+) ──[220Ω resistor]── GPIO 17 (Physical Pin 11)
  Cathode (-)───────────────── GND (Physical Pin 9)
```

**⚠️ IMPORTANT: HiFiBerry DAC Compatibility**

If using a HiFiBerry DAC (DAC+, DAC2, etc.), **DO NOT use GPIO 18, 19, 20, or 21** for IR! These pins are used by I2S audio and will cause system instability or reboots.

**Safe pins for HiFiBerry DAC users:**
- **GPIO 17 (Pin 11)** - ⭐ **RECOMMENDED DEFAULT**
- GPIO 13 (Pin 33) - hardware PWM capable
- GPIO 22, 23, 24, 25, 27

See [HIFIBERRY_DAC_COMPATIBILITY.md](HIFIBERRY_DAC_COMPATIBILITY.md) for complete GPIO reference.

## Usage

### Web Interface

After installation, access the IR Remote Control through the HiFiBerry OS web interface:

1. Open `http://hifiberry.local` in your browser
2. Navigate to Extensions or Sources menu
3. Select "IR Remote Control"

The interface provides:
- **Status Display**: Shows last command sent and current state
- **Power & Mute**: Control receiver power and mute
- **Volume Controls**: Increase or decrease volume
- **Input Selection**: Switch between 8 different inputs
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

To use a different GPIO pin, edit the install script before running:

```bash
# In install.sh, change:
IR_GPIO_PIN=17
# to your desired pin
```

Or manually edit `/boot/config.txt` after installation:

```bash
mount -o remount,rw /boot
nano /boot/config.txt
# Change: dtoverlay=gpio-ir-tx,gpio_pin=17
mount -o remount,ro /boot
reboot
```

### Customizing IR Codes

If your receiver uses different IR codes:

1. Edit `/opt/hifiberry/ir-remote-control/remote_control.py`
2. Update the `COMMANDS_TO_CODE_MAPPING` dictionary with your codes
3. Restart the service: `systemctl restart ir-api.service`

To capture codes from your existing remote, see [INSTALL.md](INSTALL.md#capturing-ir-codes-from-your-remote).

## API Endpoints

The API server runs on port 8089 and provides:

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

## Home Assistant Integration

Control your receiver directly from Home Assistant! The REST API endpoints can be easily integrated using REST commands.

### Quick Setup

Add to your `configuration.yaml`:

```yaml
rest_command:
  ir_receiver_power:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"power"}'
```

Then call from automations, scripts, or dashboard buttons:

```yaml
# In an automation
service: rest_command.ir_receiver_power

# Dashboard button
type: button
name: Power
tap_action:
  action: call-service
  service: rest_command.ir_receiver_power
```

### Complete Package

For a full-featured integration with buttons, sensors, input selectors, and automations:

1. Copy `home_assistant_package.yaml` to your Home Assistant `packages/` directory
2. Replace `hifiberry.local` with your device's IP or hostname
3. Restart Home Assistant

See [HOMEASSISTANT.md](HOMEASSISTANT.md) for:
- Complete REST command configurations
- Dashboard card examples
- Automation examples (auto power on/off, input switching)
- Voice control setup (Alexa/Google Assistant)
- Advanced features (macros, input selectors)
- Troubleshooting for connection issues and timeouts

**Note**: The API server uses threading to handle concurrent requests reliably, ensuring smooth operation when Home Assistant polls for status while sending commands.

## Service Management

### Using systemd:

```bash
# Start service
systemctl start ir-api.service

# Stop service
systemctl stop ir-api.service

# Check status
systemctl status ir-api.service

# View logs
journalctl -u ir-api.service -f
```

### Using init scripts (BusyBox):

```bash
# Start service
/etc/init.d/ir-api start

# Stop service
/etc/init.d/ir-api stop

# Check status
/etc/init.d/ir-api status

# View logs
tail -f /var/log/ir-api.log
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

3. **Check LED with phone camera:**
   - Point phone camera at IR LED
   - Send a command
   - You should see LED flash purple/white on camera

4. **Verify GPIO pin configuration:**
```bash
grep gpio-ir-tx /boot/config.txt
# Should show: dtoverlay=gpio-ir-tx,gpio_pin=17
```

### Service Not Running

```bash
# Check status
systemctl status ir-api.service

# View logs
journalctl -u ir-api.service -n 50

# Restart service
systemctl restart ir-api.service
```

### Web Interface Not Showing

1. **Verify extension is installed:**
```bash
ls -la /opt/beocreate/beo-extensions/ir-remote-control/
```

2. **Restart Beocreate:**
```bash
systemctl restart beocreate2
```

3. **Check API server:**
```bash
curl http://localhost:8089/api/status
```

### Wrong IR Codes

If commands are sent but receiver doesn't respond:
- Your receiver may use a different IR protocol
- IR codes may not match your receiver
- Verify receiver is in range with clear line of sight

For detailed troubleshooting, see [DEBUG.md](DEBUG.md).

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

## Advanced Options

### audiocontrol2 Integration

For advanced users, you can integrate IR commands into the official HiFiBerry audiocontrol2 API on port 81. This provides:
- Unified API with all HiFiBerry functions
- Better integration with home automation
- Standard HiFiBerry API conventions

See [audiocontrol2_integration/README_AUDIOCONTROL2.md](audiocontrol2_integration/README_AUDIOCONTROL2.md) for details.

**Both APIs can run simultaneously!**

## File Structure

```
/opt/hifiberry/ir-remote-control/
├── remote_control.py          # Main IR control script
├── ir_api_server.py          # API server for web interface
└── status.json               # Current status (created at runtime)

/opt/beocreate/beo-extensions/ir-remote-control/
├── index.js                  # Beocreate extension registration
├── menu.html                 # Web interface HTML
├── ir-remote-client.js       # Client-side JavaScript
└── package.json              # Extension metadata

/etc/systemd/system/
└── ir-api.service           # Systemd service file

/etc/init.d/
└── ir-api                   # BusyBox init script
```

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

### How It Works

1. **IR Transmission**: Uses `ir-ctl` command with kernel `gpio-ir-tx` driver
2. **API Server**: Python threaded HTTP server provides REST API for web interface and Home Assistant
   - Supports concurrent requests from multiple clients
   - Robust error handling and graceful degradation
   - Keep-alive connections for reliability
3. **Web Interface**: Beocreate extension polls API and sends commands
4. **Home Assistant Integration**: REST commands and sensors for automation
5. **Status Updates**: Current status written to JSON file for persistence

## Contributing

Contributions welcome! Areas for improvement:
- Support for additional IR protocols
- Learning mode to capture remote codes
- Macro support (sequences of commands)
- Integration with HiFiBerry player events
- Additional receiver models/brands

## License

MIT License - see LICENSE file for details.

## Credits

- Inspired by [hifiberry_fan_control](https://github.com/Leoname/hifiberry_fan_control)
- Built for HiFiBerry OS - minimal Linux distribution for audio
- Uses `ir-ctl` from v4l-utils package

## Support

For issues or questions:
- Check [DEBUG.md](DEBUG.md) for troubleshooting
- Review [INSTALL.md](INSTALL.md) for installation help
- Test IR transmission with `ir-ctl` directly
- Verify hardware connections

## Acknowledgments

- HiFiBerry team for the excellent HiFiBerry OS
- Beocreate framework for extension support
- Linux kernel IR subsystem developers
- v4l-utils developers for `ir-ctl` tool

---

**Enjoy controlling your receiver from HiFiBerry OS! 🎵📡**
