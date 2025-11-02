# IR Remote Controller - audiocontrol2 Integration

This integration adds your IR remote control commands to the official HiFiBerry audiocontrol2 API, allowing you to control your receiver through the standard HiFiBerry API endpoints.

## What This Provides

### Dual API Access
You get **two ways** to control your IR remote:

1. **Standalone API** (port 8089) - Already working with your Beocreate web UI
2. **audiocontrol2 API** (port 81) - **NEW!** Integrated with official HiFiBerry API

### Benefits of audiocontrol2 Integration

✅ **Unified API** - All HiFiBerry functions in one place  
✅ **Standard Endpoints** - Follows HiFiBerry API conventions  
✅ **Better Integration** - Works with other HiFiBerry services  
✅ **Automation Ready** - Easy to integrate with home automation  
✅ **Future-Proof** - Compatible with HiFiBerry updates  

## Architecture

```
┌─────────────────────────────────────────────────┐
│          HiFiBerry audiocontrol2                │
│                 (Port 81)                       │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐ │
│  │ Player   │  │ Metadata │  │ IR Remote    │ │
│  │Controller│  │Controller│  │Controller ⭐ │ │
│  └──────────┘  └──────────┘  └──────────────┘ │
│                                                 │
└─────────────────────────────────────────────────┘
                     │
                     │ ir-ctl
                     ▼
              ┌─────────────┐
              │ /dev/lirc0  │
              │   GPIO 17   │
              └─────────────┘
                     │
                     ▼
              [ IR LED ] ──→ Receiver
```

## Installation

### Prerequisites

1. **Standalone plugin already installed** (from main install.sh)
2. **audiocontrol2 installed** (should be on HiFiBerry OS by default)
3. **IR transmitter working** (GPIO 17 configured)

### Install audiocontrol2 Integration

```bash
cd audiocontrol2_integration
chmod +x install_audiocontrol2_integration.sh
./install_audiocontrol2_integration.sh
```

The installer will:
- Locate audiocontrol2 installation
- Install IR remote controller
- Register controller with audiocontrol2
- Restart audiocontrol2 service

## API Usage

### Base URL

```
http://<hifiberry-ip>:81/api/ir_remote
```

### Endpoints

#### 1. Send Command

```bash
POST /api/ir_remote/send
Content-Type: application/json

{
  "command": "power"
}
```

**Example:**
```bash
curl -X POST http://localhost:81/api/ir_remote/send \
  -H 'Content-Type: application/json' \
  -d '{"command":"power"}'
```

**Response:**
```json
{
  "success": true,
  "command": "power",
  "ir_code": "0xd26d04",
  "message": "Transmitted 'power' signal"
}
```

#### 2. Get Status

```bash
GET /api/ir_remote/status
```

**Example:**
```bash
curl http://localhost:81/api/ir_remote/status
```

**Response:**
```json
{
  "ir_device": "/dev/lirc0",
  "last_command": "power",
  "last_status": "Success",
  "available": true,
  "commands_available": 12
}
```

#### 3. List Available Commands

```bash
GET /api/ir_remote/commands
```

**Example:**
```bash
curl http://localhost:81/api/ir_remote/commands
```

**Response:**
```json
{
  "power": "0xd26d04",
  "mute": "0xd26d05",
  "volume_up": "0xd26d02",
  "volume_down": "0xd26d03",
  "input_tuner": "0xd26d0b",
  ...
}
```

#### 4. Volume Controls (Shortcuts)

```bash
POST /api/ir_remote/volume_up
POST /api/ir_remote/volume_down
POST /api/ir_remote/mute
POST /api/ir_remote/power
```

**Example:**
```bash
curl -X POST http://localhost:81/api/ir_remote/volume_up
```

#### 5. Set Input

```bash
POST /api/ir_remote/set_input
Content-Type: application/json

{
  "input": "cd"
}
```

**Example:**
```bash
curl -X POST http://localhost:81/api/ir_remote/set_input \
  -H 'Content-Type: application/json' \
  -d '{"input":"cd"}'
```

Available inputs: `tuner`, `phono`, `cd`, `direct`, `video1`, `video2`, `tape1`, `tape2`

## Integration Examples

### Home Assistant

```yaml
# configuration.yaml
rest_command:
  receiver_power:
    url: "http://hifiberry.local:81/api/ir_remote/send"
    method: POST
    content_type: 'application/json'
    payload: '{"command":"power"}'
  
  receiver_volume_up:
    url: "http://hifiberry.local:81/api/ir_remote/volume_up"
    method: POST
  
  receiver_volume_down:
    url: "http://hifiberry.local:81/api/ir_remote/volume_down"
    method: POST
  
  receiver_input_cd:
    url: "http://hifiberry.local:81/api/ir_remote/set_input"
    method: POST
    content_type: 'application/json'
    payload: '{"input":"cd"}'
```

### Node-RED

```json
[
  {
    "id": "ir_remote_power",
    "type": "http request",
    "method": "POST",
    "url": "http://hifiberry.local:81/api/ir_remote/send",
    "payload": "{\"command\":\"power\"}",
    "headers": {
      "content-type": "application/json"
    }
  }
]
```

### Python Script

```python
import requests

# HiFiBerry audiocontrol2 API
HIFIBERRY_API = "http://hifiberry.local:81/api/ir_remote"

def send_ir_command(command):
    """Send IR command via HiFiBerry API"""
    response = requests.post(
        f"{HIFIBERRY_API}/send",
        json={"command": command}
    )
    return response.json()

def get_ir_status():
    """Get IR controller status"""
    response = requests.get(f"{HIFIBERRY_API}/status")
    return response.json()

# Usage
send_ir_command("power")
send_ir_command("volume_up")
status = get_ir_status()
print(status)
```

### Shell Script Automation

```bash
#!/bin/bash
# morning_routine.sh - Turn on receiver and set to tuner

API="http://hifiberry.local:81/api/ir_remote"

# Power on
curl -X POST "$API/send" \
  -H 'Content-Type: application/json' \
  -d '{"command":"power"}'

# Wait for receiver to power up
sleep 3

# Switch to tuner
curl -X POST "$API/set_input" \
  -H 'Content-Type: application/json' \
  -d '{"input":"tuner"}'

# Set volume
curl -X POST "$API/volume_up"
curl -X POST "$API/volume_up"
```

## Configuration

### Edit Command Mappings

```bash
# Edit the configuration file
nano /opt/hifiberry/audiocontrol2/config/ir_remote.conf

# Modify commands section
[commands]
power = 0xYOURCODE
volume_up = 0xYOURCODE
# ... etc
```

### Change GPIO Pin

```bash
# Edit configuration
nano /opt/hifiberry/audiocontrol2/config/ir_remote.conf

# Change gpio_pin value
[ir_remote]
gpio_pin = 22

# Also update /boot/config.txt
mount -o remount,rw /boot
nano /boot/config.txt
# Change: dtoverlay=gpio-ir-tx,gpio_pin=22
mount -o remount,ro /boot
reboot
```

## File Locations

```
/opt/hifiberry/audiocontrol2/
├── ac2/
│   └── controllers/
│       └── ir_remote_controller.py    # Controller implementation
└── config/
    ├── ir_remote.conf                 # Configuration file
    └── controllers.conf               # Controller registration
```

## Comparison: Standalone vs audiocontrol2 API

| Feature | Standalone (Port 8089) | audiocontrol2 (Port 81) |
|---------|------------------------|-------------------------|
| **Web UI** | ✅ Beocreate extension | ❌ API only |
| **API Access** | ✅ REST API | ✅ REST API |
| **HiFiBerry Integration** | ❌ Separate | ✅ Integrated |
| **Home Automation** | ✅ Yes | ✅ Yes (preferred) |
| **Auto-start** | ✅ systemd service | ✅ Part of audiocontrol2 |
| **Configuration** | File-based | audiocontrol2 config |

### Recommendation

- **Use Standalone API (8089)** for: Web UI control, testing, development
- **Use audiocontrol2 API (81)** for: Home automation, scripting, integrations

**Both can run simultaneously!** The web UI uses port 8089, while automation/scripts can use port 81.

## Troubleshooting

### Controller Not Loading

```bash
# Check audiocontrol2 logs
journalctl -u audiocontrol2 -f

# Check if controller is registered
grep "ir_remote" /opt/hifiberry/audiocontrol2/config/controllers.conf
```

### API Not Responding

```bash
# Check audiocontrol2 is running
systemctl status audiocontrol2

# Test API
curl http://localhost:81/api/ir_remote/status

# Check IR device
ls -la /dev/lirc0
```

### Commands Not Working

```bash
# Test controller directly
python3 /opt/hifiberry/audiocontrol2/ac2/controllers/ir_remote_controller.py

# Test with ir-ctl
ir-ctl -d /dev/lirc0 -S necx:0xd26d04
```

## Uninstalling

To remove audiocontrol2 integration (keeps standalone API):

```bash
# Remove controller
rm /opt/hifiberry/audiocontrol2/ac2/controllers/ir_remote_controller.py

# Remove config
rm /opt/hifiberry/audiocontrol2/config/ir_remote.conf

# Remove from controllers.conf
nano /opt/hifiberry/audiocontrol2/config/controllers.conf
# Delete the ir_remote line

# Restart audiocontrol2
systemctl restart audiocontrol2
```

The standalone API (port 8089) and web UI will continue to work.

## Reference Links

- [HiFiBerry audiocontrol2 API Documentation](https://github.com/hifiberry/audiocontrol2/blob/master/doc/api.md)
- [HiFiBerry OS Documentation](https://www.hifiberry.com/docs/)
- [HiFiBerry Support Forum](https://support.hifiberry.com/)

## Credits

Integration follows the audiocontrol2 controller architecture and API conventions from the [HiFiBerry audiocontrol2 project](https://github.com/hifiberry/audiocontrol2).

---

**Now you have professional-grade IR remote control integrated with the official HiFiBerry API!** 🎵📡

