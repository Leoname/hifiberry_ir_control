# Debugging and Troubleshooting Guide

This guide provides comprehensive troubleshooting steps for the IR Remote Control plugin for HiFiBerry OS.

## Quick Diagnostic Commands

Run these commands to quickly check system status:

```bash
# Check if IR device exists
ls -la /dev/lirc*

# Check service status
systemctl status ir-api.service    # or: /etc/init.d/ir-api status

# Test IR transmission
ir-ctl -d /dev/lirc0 -S necx:0xd26d04

# Test API server
curl http://localhost:8089/api/status

# Check if extension is installed
ls -la /opt/beocreate/beo-extensions/ir-remote-control/

# View service logs
journalctl -u ir-api.service -f    # or: tail -f /var/log/ir-api.log

# Check API server version (should show "threaded server" for v2+)
journalctl -u ir-api.service -n 5 | grep -i "threaded\|starting"
```

**For Home Assistant issues**, see [HOMEASSISTANT.md](HOMEASSISTANT.md#troubleshooting) for specific troubleshooting steps including:
- Empty reply errors
- SSL connection errors
- Timeout issues
- Recommended configuration settings

## Problem Categories

### 1. IR Hardware/Transmission Issues

#### IR LED Not Working

**Symptoms:**
- Commands sent from web interface but receiver doesn't respond
- `ir-ctl` command succeeds but no visible effect

**Diagnostic Steps:**

1. **Check if IR device exists:**
```bash
ls -la /dev/lirc*
# Should show: /dev/lirc0
```

If `/dev/lirc0` doesn't exist:
```bash
# Check if overlay is configured
grep gpio-ir-tx /boot/config.txt

# If not found, add it:
mount -o remount,rw /boot
echo "dtoverlay=gpio-ir-tx,gpio_pin=17" >> /boot/config.txt
mount -o remount,ro /boot
reboot
```

2. **Check kernel messages:**
```bash
dmesg | grep -i "gpio-ir\|lirc"

# Should show something like:
# [    X.XXXXXX] rc rc0: GPIO IR Bit Banging Transmitter as /devices/platform/ir-tx@11/rc/rc0
```

3. **Verify GPIO pin is exported and configured:**
```bash
# Check if pin is in use
cat /sys/kernel/debug/gpio

# Test GPIO manually (example for GPIO 17)
echo 17 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio17/direction
echo 1 > /sys/class/gpio/gpio17/value
# LED should be on (check with phone camera)
echo 0 > /sys/class/gpio/gpio17/value
echo 17 > /sys/class/gpio/unexport
```

4. **Test IR LED with phone camera:**
   - Point phone camera at IR LED
   - Send a command: `ir-ctl -d /dev/lirc0 -S necx:0xd26d04`
   - You should see LED flash purple/white on camera screen
   - If no flash visible, check LED polarity and connections

5. **Verify correct GPIO pin:**
```bash
# Check which pin is configured
grep gpio-ir-tx /boot/config.txt
```

See [`find_ir_led_pin.sh`](find_ir_led_pin.sh) script to systematically test all possible GPIO pins.

#### Wrong IR Codes

**Symptoms:**
- IR LED flashes (visible on camera) but receiver doesn't respond
- Commands work but perform wrong actions

**Solutions:**

1. **Verify your receiver uses NEC Extended protocol**
   - Most modern receivers use NEC, Sony, or RC5 protocols
   - Default codes in this plugin are NEC Extended format

2. **Capture codes from your original remote:**
```bash
# Set up IR receiver (if you have one)
mount -o remount,rw /boot
echo "dtoverlay=gpio-ir,gpio_pin=23" >> /boot/config.txt
mount -o remount,ro /boot
reboot

# Capture codes
ir-ctl -d /dev/lirc1 --receive=captured.txt
# Press buttons on original remote

# View captured codes
cat captured.txt
```

3. **Update codes in remote_control.py:**
```bash
nano /opt/hifiberry/ir-remote-control/remote_control.py

# Modify COMMANDS_TO_CODE_MAPPING dictionary
# Then restart service:
systemctl restart ir-api.service
```

#### GPIO Conflicts

**Symptoms:**
- System becomes unstable when IR device is configured
- Random reboots after enabling IR
- Audio dropouts or crackling

**Solutions:**

1. **Check for HiFiBerry DAC conflicts:**
   - GPIO 18, 19, 20, 21 are used by I2S audio
   - **Never use these pins for IR if you have a HiFiBerry DAC!**

2. **Check for fan control conflicts:**
```bash
# Check if fan control is using GPIO 12
systemctl status fan-control.service
cat /opt/hifiberry/fan-control/fan_control.py | grep GPIO_PIN
```

3. **Use safe GPIO pin (17 recommended):**
```bash
mount -o remount,rw /boot
nano /boot/config.txt
# Change to: dtoverlay=gpio-ir-tx,gpio_pin=17
mount -o remount,ro /boot
reboot
```

See [`HIFIBERRY_DAC_COMPATIBILITY.md`](HIFIBERRY_DAC_COMPATIBILITY.md) for complete GPIO reference.

### 2. Service Issues

#### Service Won't Start

**Symptoms:**
- `systemctl status ir-api.service` shows "failed" or "inactive"
- Web interface shows "API server not responding"

**Diagnostic Steps:**

1. **Check service status:**
```bash
systemctl status ir-api.service
# or
/etc/init.d/ir-api status
```

2. **View detailed logs:**
```bash
journalctl -u ir-api.service -n 50
# or
tail -f /var/log/ir-api.log
```

3. **Test script manually:**
```bash
# Stop the service first
systemctl stop ir-api.service

# Run script directly to see errors
python3 /opt/hifiberry/ir-remote-control/ir_api_server.py

# If it starts successfully, press Ctrl+C and restart service
systemctl start ir-api.service
```

4. **Common errors:**

**Port already in use:**
```bash
netstat -tuln | grep 8089

# If port is occupied, find and kill process:
lsof -i :8089
# Or edit ir_api_server.py to use different port
```

**Permission errors:**
```bash
# Ensure files have correct permissions
chmod +x /opt/hifiberry/ir-remote-control/*.py
```

**Python errors:**
```bash
# Check Python version
python3 --version
# Should be 3.x

# Test script syntax
python3 -m py_compile /opt/hifiberry/ir-remote-control/ir_api_server.py
```

#### Service Starts But Doesn't Respond

**Symptoms:**
- Service shows "active (running)" but API requests fail
- `curl http://localhost:8089/api/status` times out or gives error

**Solutions:**

1. **Check if service is actually listening:**
```bash
netstat -tuln | grep 8089
# Should show: tcp   0   0 0.0.0.0:8089   0.0.0.0:*   LISTEN
```

2. **Test from localhost:**
```bash
curl http://localhost:8089/api/status

# If this works but web interface doesn't, check firewall
```

3. **Check service is binding to correct interface:**
```bash
# View ir_api_server.py configuration
grep "API_PORT\|server_address" /opt/hifiberry/ir-remote-control/ir_api_server.py

# Should bind to 0.0.0.0 (all interfaces) or specific IP
```

4. **Restart service:**
```bash
systemctl restart ir-api.service
journalctl -u ir-api.service -f
# Watch for startup errors
```

### 3. Web Interface Issues

#### Extension Not Showing in UI

**Symptoms:**
- IR Remote Control doesn't appear in Beocreate sources/extensions menu
- No errors in browser console

**Diagnostic Steps:**

1. **Verify files are installed:**
```bash
ls -la /opt/beocreate/beo-extensions/ir-remote-control/

# Should show:
# index.js
# menu.html
# ir-remote-client.js
# package.json
```

2. **Check package.json is valid:**
```bash
cat /opt/beocreate/beo-extensions/ir-remote-control/package.json
# Should be valid JSON with "name" field
```

3. **Check Beocreate logs for extension loading:**
```bash
journalctl -u beocreate2 -n 100 | grep -i "extension\|ir-remote"

# Look for:
# - Extension loading messages
# - Error messages
```

4. **Restart Beocreate:**
```bash
systemctl restart beocreate2

# Wait 10 seconds then check logs
journalctl -u beocreate2 -f
```

5. **Check for JavaScript errors:**
```bash
# Look for syntax errors in index.js
node -c /opt/beocreate/beo-extensions/ir-remote-control/index.js
```

#### Extension Shows But Buttons Don't Work

**Symptoms:**
- IR Remote Control appears in UI
- Clicking buttons does nothing
- Browser console shows errors

**Diagnostic Steps:**

1. **Open browser developer tools (F12)**
   - Check Console tab for JavaScript errors
   - Look for messages like "Can't find variable: irRemoteControl"

2. **Check if client script is loaded:**
```bash
# View page source in browser
# Search for: ir-remote-client.js
# Script tag should be present in the HTML
```

3. **Test script loading manually in browser console:**
```javascript
// In browser console, try:
typeof irRemoteControl
// Should return "object", not "undefined"

// Manually load script:
var s = document.createElement('script');
s.src = '/extensions/ir-remote-control/ir-remote-client.js';
s.onload = function() { console.log('✓ Script loaded!'); };
document.head.appendChild(s);
```

4. **Check if API server is reachable from browser:**
```javascript
// In browser console:
fetch('http://hifiberry.local:8089/api/status')
  .then(r => r.json())
  .then(d => console.log(d))
  .catch(e => console.error('API Error:', e));
```

5. **Verify menu.html script tag placement:**
```bash
# Script tag should be INSIDE the menu-screen div
tail -10 /opt/beocreate/beo-extensions/ir-remote-control/menu.html

# Should show script tag before the closing </div>
```

#### API Connection Errors

**Symptoms:**
- Web interface shows "Failed to connect to API server"
- Browser console shows CORS or connection errors

**Solutions:**

1. **Check API server is running:**
```bash
systemctl status ir-api.service
curl http://localhost:8089/api/status
```

2. **Check hostname resolution:**
```bash
# From the HiFiBerry device
ping hifiberry.local
# or
ping $(hostname -I | awk '{print $1}')
```

3. **Test API from browser network:**
   - Open browser developer tools
   - Go to Network tab
   - Click a button in IR Remote Control UI
   - Check for failed requests to port 8089

4. **Check CORS configuration (if needed):**
```python
# In ir_api_server.py, IRAPIHandler should have CORS headers:
self.send_header('Access-Control-Allow-Origin', '*')
```

### 4. Command Execution Issues

#### Commands Sent But Status Not Updated

**Symptoms:**
- Buttons click and highlight
- No errors shown
- Status shows "None" or old command

**Solutions:**

1. **Check API logs:**
```bash
journalctl -u ir-api.service -f
# or
tail -f /var/log/ir-api.log

# Click buttons in UI and watch for API requests
```

2. **Test command manually:**
```bash
# Test remote_control.py directly
python3 /opt/hifiberry/ir-remote-control/remote_control.py -c power

# Should show: ✓ Transmitted 'power' signal (code: 0xd26d04)
```

3. **Test via API:**
```bash
curl -X POST http://localhost:8089/api/send \
  -H "Content-Type: application/json" \
  -d '{"command":"power"}'

# Check response
```

4. **Verify ir-ctl is working:**
```bash
which ir-ctl
ir-ctl --version
ir-ctl -d /dev/lirc0 --features
```

#### Slow Response or Timeouts

**Symptoms:**
- Long delay before command executes
- API requests timeout
- UI becomes unresponsive

**Solutions:**

1. **Check system resources:**
```bash
top
# Look for high CPU or memory usage

free -h
# Check available memory

df -h
# Check disk space
```

2. **Check for multiple instances:**
```bash
ps aux | grep ir_api_server
# Should only show one process (plus grep)

# If multiple, kill extras:
killall python3
systemctl restart ir-api.service
```

3. **Reduce logging verbosity:**
   - Edit `ir_api_server.py` and reduce debug output

4. **Verify threading support:**
```bash
# Check if using ThreadingHTTPServer (v2+)
grep -i "ThreadingHTTPServer\|threaded server" /opt/hifiberry/ir-remote-control/ir_api_server.py

# If not found, update to latest version
cd /tmp && git clone https://github.com/Leoname/hifiberry_ir_control.git
cd hifiberry_ir_control && chmod +x install.sh && ./install.sh
```

**Note:** The API server uses `ThreadingHTTPServer` (v2+) to handle concurrent requests from Home Assistant, web interface, and other clients simultaneously without blocking.

### 5. Read-Only Filesystem Issues

**Symptoms:**
- Cannot modify `/boot/config.txt`
- Error: "Read-only file system"

**Solution:**

HiFiBerry OS uses read-only filesystem for stability. To make changes:

```bash
# Remount as read-write
mount -o remount,rw /boot

# Make your changes
nano /boot/config.txt

# Remount as read-only
mount -o remount,ro /boot

# Reboot if kernel modules changed
reboot
```

The installation scripts handle this automatically.

## Advanced Debugging

### Enable Verbose Logging

Edit `/opt/hifiberry/ir-remote-control/ir_api_server.py`:

```python
# Add at top of IRAPIHandler class
def log_message(self, format, *args):
    # Uncomment to enable verbose request logging
    BaseHTTPRequestHandler.log_message(self, format, *args)
```

Restart service:
```bash
systemctl restart ir-api.service
journalctl -u ir-api.service -f
```

### Check Beocreate Extension Loading

```bash
# Stop Beocreate
systemctl stop beocreate2

# Run Beocreate in foreground to see all output
cd /opt/beocreate
node beo-system/beo-server.js

# Watch for IR Remote Control extension loading
# Press Ctrl+C when done, then restart service
systemctl start beocreate2
```

### Test GPIO Pin with Python

```python
#!/usr/bin/env python3
import time
import subprocess

PIN = 17

# Export pin
with open('/sys/class/gpio/export', 'w') as f:
    f.write(str(PIN))

time.sleep(0.1)

# Set as output
with open(f'/sys/class/gpio/gpio{PIN}/direction', 'w') as f:
    f.write('out')

# Blink LED 5 times
for i in range(5):
    with open(f'/sys/class/gpio/gpio{PIN}/value', 'w') as f:
        f.write('1')
    time.sleep(0.5)
    with open(f'/sys/class/gpio/gpio{PIN}/value', 'w') as f:
        f.write('0')
    time.sleep(0.5)

# Cleanup
with open('/sys/class/gpio/unexport', 'w') as f:
    f.write(str(PIN))

print("Done! Check if LED blinked (visible with phone camera)")
```

### Capture Network Traffic

To debug API communication:

```bash
# Install tcpdump if available
tcpdump -i any -s 0 -w /tmp/ir_api.pcap port 8089

# Reproduce issue, then stop tcpdump (Ctrl+C)
# Analyze with wireshark or:
tcpdump -r /tmp/ir_api.pcap -A
```

## Getting More Help

If issues persist after trying these steps:

1. **Collect diagnostic information:**
```bash
# Save system info
uname -a > /tmp/debug_info.txt
python3 --version >> /tmp/debug_info.txt
ir-ctl --version >> /tmp/debug_info.txt

# Save service status
systemctl status ir-api.service >> /tmp/debug_info.txt 2>&1

# Save logs
journalctl -u ir-api.service -n 100 >> /tmp/debug_info.txt

# Save config
grep gpio-ir /boot/config.txt >> /tmp/debug_info.txt

# Test commands
ir-ctl -d /dev/lirc0 --features >> /tmp/debug_info.txt 2>&1
curl http://localhost:8089/api/status >> /tmp/debug_info.txt 2>&1
```

2. **Review documentation:**
   - [`README.md`](README.md) - Overview and usage
   - [`INSTALL.md`](INSTALL.md) - Installation guide
   - [`HIFIBERRY_DAC_COMPATIBILITY.md`](HIFIBERRY_DAC_COMPATIBILITY.md) - GPIO reference

3. **Check HiFiBerry forums and documentation:**
   - [HiFiBerry OS documentation](https://www.hifiberry.com/docs/)
   - [HiFiBerry community forums](https://www.hifiberry.com/community/)

4. **Test with minimal setup:**
   - Test IR transmission with `ir-ctl` directly
   - Test API server standalone without Beocreate
   - Test GPIO pin with simple Python script

## Common Error Messages and Solutions

| Error Message | Possible Cause | Solution |
|---------------|----------------|----------|
| `Cannot open /dev/lirc0` | IR device not configured | Check `/boot/config.txt` and reboot |
| `Permission denied` | Script not executable or running as non-root | Check permissions: `chmod +x *.py` |
| `Address already in use` | Port 8089 occupied | Find conflicting process: `netstat -tuln \| grep 8089` |
| `Command not found: ir-ctl` | ir-ctl not installed | Should be included in HiFiBerry OS, check `which ir-ctl` |
| `Failed to connect to API` | Service not running or port blocked | Check service status and firewall |
| `Can't find variable: irRemoteControl` | Client script not loaded | Check menu.html script tag placement |
| `GPIO XX already in use` | Pin conflict with another service | Choose different GPIO pin |

---

For additional help or to report bugs, please check the project repository on GitHub.

