# Dual API Architecture Guide

Your IR Remote Control plugin now supports **TWO API access methods**, giving you maximum flexibility!

## 🎯 Quick Decision Guide

**Choose your API based on your use case:**

| Use Case | Recommended API | Port | Installation |
|----------|----------------|------|--------------|
| **Web UI Control** | Standalone | 8089 | ✅ Default |
| **Manual Testing** | Standalone | 8089 | ✅ Default |
| **Home Automation** | audiocontrol2 | 81 | Optional |
| **Scripting** | audiocontrol2 | 81 | Optional |
| **HiFiBerry Integration** | audiocontrol2 | 81 | Optional |
| **Quick Setup** | Standalone | 8089 | ✅ Default |
| **Professional Setup** | Both! | 8089 + 81 | Recommended |

## 📊 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Your HiFiBerry Device                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────┐      ┌─────────────────────────┐ │
│  │   Standalone API     │      │  audiocontrol2 API      │ │
│  │   (Port 8089)        │      │  (Port 81)              │ │
│  ├──────────────────────┤      ├─────────────────────────┤ │
│  │ ✅ Web UI            │      │ ✅ HiFiBerry API        │ │
│  │ ✅ Simple REST       │      │ ✅ Unified endpoint     │ │
│  │ ✅ Beocreate         │      │ ✅ Standard format      │ │
│  │ ✅ Independent       │      │ ✅ System integration   │ │
│  └──────────────────────┘      └─────────────────────────┘ │
│             │                              │                │
│             └──────────────┬───────────────┘                │
│                            │                                │
│                    ┌───────▼────────┐                       │
│                    │ remote_control │                       │
│                    │     .py        │                       │
│                    └───────┬────────┘                       │
│                            │                                │
│                    ┌───────▼────────┐                       │
│                    │   ir-ctl       │                       │
│                    └───────┬────────┘                       │
│                            │                                │
│                    ┌───────▼────────┐                       │
│                    │  /dev/lirc0    │                       │
│                    │   GPIO 17      │                       │
│                    └───────┬────────┘                       │
└────────────────────────────┼────────────────────────────────┘
                             │
                      [IR LED] ──→ Your Receiver
```

## 🚀 Installation Options

### Option 1: Quick Setup (Standalone Only)

**Perfect for:** Getting started quickly, testing, web UI control

```bash
# Just run the main installer
./install.sh
```

**You get:**
- ✅ Web interface (Beocreate extension)
- ✅ Standalone API on port 8089
- ✅ Full IR control functionality
- ✅ 5-minute setup

### Option 2: Professional Setup (Both APIs)

**Perfect for:** Home automation, advanced integrations, production use

```bash
# Step 1: Install standalone
./install.sh

# Step 2: Add audiocontrol2 integration
cd audiocontrol2_integration
./install_audiocontrol2_integration.sh
```

**You get:**
- ✅ Everything from Option 1
- ✅ audiocontrol2 API on port 81
- ✅ Unified HiFiBerry API access
- ✅ Better automation integration
- ✅ 10-minute setup

## 📡 API Comparison

### Standalone API (Port 8089)

**Endpoint Format:**
```bash
http://<hifiberry-ip>:8089/api/<endpoint>
```

**Examples:**
```bash
# Send command
curl -X POST http://localhost:8089/api/send \
  -H 'Content-Type: application/json' \
  -d '{"command":"power"}'

# Get status
curl http://localhost:8089/api/status

# List commands
curl http://localhost:8089/api/commands
```

**Best For:**
- Web interface backend
- Quick testing
- Development
- Standalone operation

### audiocontrol2 API (Port 81)

**Endpoint Format:**
```bash
http://<hifiberry-ip>:81/api/ir_remote/<endpoint>
```

**Examples:**
```bash
# Send command
curl -X POST http://localhost:81/api/ir_remote/send \
  -H 'Content-Type: application/json' \
  -d '{"command":"power"}'

# Get status
curl http://localhost:81/api/ir_remote/status

# Volume shortcuts
curl -X POST http://localhost:81/api/ir_remote/volume_up
curl -X POST http://localhost:81/api/ir_remote/volume_down

# Set input
curl -X POST http://localhost:81/api/ir_remote/set_input \
  -H 'Content-Type: application/json' \
  -d '{"input":"cd"}'
```

**Best For:**
- Home automation (Home Assistant, Node-RED)
- Scripting and automation
- Integration with other HiFiBerry functions
- Professional deployments

## 🔄 Can I Use Both?

**YES!** Both APIs run independently and simultaneously.

**Common scenario:**
- **Web UI** uses standalone API (port 8089)
- **Home automation** uses audiocontrol2 API (port 81)

This gives you:
- Beautiful web interface for manual control
- Professional API for automation
- No conflicts, no problems!

## 🏠 Home Automation Examples

### Home Assistant (Using audiocontrol2)

```yaml
rest_command:
  receiver_power:
    url: "http://hifiberry.local:81/api/ir_remote/power"
    method: POST
  
  receiver_input_cd:
    url: "http://hifiberry.local:81/api/ir_remote/set_input"
    method: POST
    content_type: 'application/json'
    payload: '{"input":"cd"}'

automation:
  - alias: "Morning Audio"
    trigger:
      platform: time
      at: "07:00:00"
    action:
      - service: rest_command.receiver_power
      - delay: '00:00:03'
      - service: rest_command.receiver_input_cd
```

### Node-RED

```json
[
  {
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

## 🔧 Configuration

### Standalone API

**Config file:** `/opt/hifiberry/ir-remote-control/remote_control.py`

**Service:** `ir-api.service`

**Logs:**
```bash
journalctl -u ir-api.service -f
```

### audiocontrol2 API

**Config file:** `/opt/hifiberry/audiocontrol2/config/ir_remote.conf`

**Service:** Part of `audiocontrol2.service`

**Logs:**
```bash
journalctl -u audiocontrol2 -f
```

## 🐛 Troubleshooting

### Standalone API Not Responding

```bash
# Check service
systemctl status ir-api.service

# Test endpoint
curl http://localhost:8089/api/status

# Restart service
systemctl restart ir-api.service
```

### audiocontrol2 API Not Responding

```bash
# Check service
systemctl status audiocontrol2

# Test endpoint
curl http://localhost:81/api/ir_remote/status

# Check controller is loaded
grep ir_remote /opt/hifiberry/audiocontrol2/config/controllers.conf

# Restart service
systemctl restart audiocontrol2
```

### Both APIs Not Working

**Check IR device:**
```bash
# Device exists?
ls -la /dev/lirc0

# Test directly
ir-ctl -d /dev/lirc0 -S necx:0xd26d04

# Check GPIO config
grep gpio-ir /boot/config.txt
```

## 📚 Documentation

- **Main README:** [`README.md`](README.md) - Complete documentation
- **Quick Start:** [`QUICKSTART.md`](QUICKSTART.md) - 3-step installation
- **audiocontrol2:** [`audiocontrol2_integration/README_AUDIOCONTROL2.md`](audiocontrol2_integration/README_AUDIOCONTROL2.md) - API integration details
- **Project Summary:** [`PROJECT_SUMMARY.md`](PROJECT_SUMMARY.md) - Project overview

## ⚡ Performance

Both APIs are lightweight and run simultaneously without issues:

- **Standalone API:** ~5MB RAM, minimal CPU
- **audiocontrol2:** Already running on HiFiBerry OS
- **Combined:** Negligible overhead

## 🎓 Best Practices

### For Development
1. Use standalone API for testing
2. Access web UI for manual testing
3. Monitor logs with `journalctl`

### For Production
1. Install both APIs
2. Use web UI for manual control
3. Use audiocontrol2 for automation
4. Monitor both services

### For Home Automation
1. Use audiocontrol2 API (port 81)
2. Follows HiFiBerry conventions
3. Better integration with HiFiBerry ecosystem
4. Consistent with other HiFiBerry functions

## 🔒 Security

Both APIs run on localhost by default:
- **Standalone:** Accessible from local network
- **audiocontrol2:** Follows audiocontrol2 security settings

For external access, use:
- Reverse proxy (nginx, Apache)
- VPN
- SSH tunnel

## 📈 Migration Path

**Start simple, grow as needed:**

1. **Week 1:** Install standalone, use web UI
2. **Week 2:** Test commands, verify functionality
3. **Week 3:** Add audiocontrol2 integration
4. **Week 4:** Set up home automation
5. **Ongoing:** Both APIs working together

## 🎉 Summary

### You Now Have:

✅ **Dual API architecture**
- Standalone API for web UI (port 8089)
- audiocontrol2 integration for automation (port 81)

✅ **Maximum flexibility**
- Use one or both
- Switch between them anytime
- No conflicts

✅ **Professional features**
- Beautiful web interface
- Standard HiFiBerry API
- Home automation ready
- Production grade

✅ **Complete documentation**
- Installation guides
- API references
- Troubleshooting
- Examples

---

**Choose your path, or use both! Either way, you're all set!** 🚀🎵

