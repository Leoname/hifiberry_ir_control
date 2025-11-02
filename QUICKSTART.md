# Quick Start Guide

## Prerequisites

✅ IR LED on GPIO 17 confirmed working  
✅ HiFiBerry OS running on Raspberry Pi  
✅ SSH access to your HiFiBerry device  

## Installation (2 Easy Steps)

### 1. Clone and Install

```bash
ssh root@<hifiberry-ip>
cd /tmp
git clone https://github.com/Leoname/hifiberry_ir_control.git
cd hifiberry_ir_control
chmod +x install.sh
./install.sh
```

**Or use the one-liner:**
```bash
ssh root@<hifiberry-ip> "cd /tmp && git clone https://github.com/Leoname/hifiberry_ir_control.git && cd hifiberry_ir_control && chmod +x install.sh && ./install.sh"
```

### 2. Reboot (if first-time IR setup)

If the installer configured IR for the first time, reboot:
```bash
reboot
```

Then run `./install.sh` again to complete the installation.

### 3. Access Web Interface

Open your browser:
```
http://<hifiberry-ip>
```

Navigate to: **Extensions → IR Remote Control**

## Quick Test

Test from command line:
```bash
# Power command
python3 /opt/hifiberry/ir-remote-control/remote_control.py -c power

# Volume up
python3 /opt/hifiberry/ir-remote-control/remote_control.py -c volume_up

# Switch to CD
python3 /opt/hifiberry/ir-remote-control/remote_control.py -c input_cd
```

## Troubleshooting

### Plugin not in web interface?
```bash
systemctl restart beocreate2
# Wait 30 seconds, then refresh browser
```

### IR not working?
```bash
# Check device
ls -la /dev/lirc0

# Test directly
ir-ctl -d /dev/lirc0 -S necx:0xd26d04

# Check service
systemctl status ir-api.service
```

### Need help?
- See full documentation in [`README.md`](README.md)
- Compare APIs in [`DUAL_API_GUIDE.md`](DUAL_API_GUIDE.md)
- Check [`PROJECT_SUMMARY.md`](PROJECT_SUMMARY.md) for overview

## File Locations

- **Scripts**: `/opt/hifiberry/ir-remote-control/`
- **Web Extension**: `/opt/beocreate/beo-extensions/ir-remote-control/`
- **API**: `http://localhost:8089`
- **Service**: `ir-api.service`

## Commands Reference

| Button | Command | Action |
|--------|---------|--------|
| Power | `power` | Toggle power |
| Mute | `mute` | Mute audio |
| 🔊 | `volume_up` | Volume + |
| 🔉 | `volume_down` | Volume - |
| Tuner | `input_tuner` | Switch input |
| Phono | `input_phono` | Switch input |
| CD | `input_cd` | Switch input |

Full list: `python3 remote_control.py --list`

---

**That's it! Your IR remote is ready to use! 🎵**

