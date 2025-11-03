# Home Assistant Timeout and Config Errors - Quick Fix

## Issues Fixed

1. **"Invalid config for 'sensor'" error** - `availability_template` not supported
2. **Timeout errors** - Commands timing out at 10 seconds
3. **Sensor not working** - Configuration incompatibility

## Quick Fix Steps

### 1. Update Your Home Assistant Configuration

Replace your current IR receiver configuration with this corrected version:

```yaml
# REST Commands - Increase timeout to 15 seconds
rest_command:
  ir_receiver_power:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"power"}'
    timeout: 15  # Changed from 10 to 15
    verify_ssl: false
    
  ir_receiver_mute:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"mute"}'
    timeout: 15
    verify_ssl: false
    
  # ... repeat for all other commands with timeout: 15

# Status Sensor - Fixed configuration
sensor:
  - platform: rest
    name: "IR Receiver Status"
    resource: "http://hifiberry.local:8089/api/status"
    method: GET
    scan_interval: 120  # Poll every 2 minutes instead of 1 minute
    timeout: 15  # Increased from 10
    force_update: false
    json_attributes:
      - last_command
      - last_status
      - timestamp
    value_template: "{{ value_json.last_status | default('Unknown') }}"
    # REMOVED: availability_template (not supported in all HA versions)
```

### 2. Use Updated Package File

Or simply replace your entire `packages/ir_receiver.yaml` with the updated version from GitHub:

```bash
# Download the latest version
cd /tmp
wget https://raw.githubusercontent.com/Leoname/hifiberry_ir_control/main/home_assistant_package.yaml

# Replace your current file
cp home_assistant_package.yaml ~/config/packages/ir_receiver.yaml

# Edit the file and replace hifiberry.local with your device's IP
nano ~/config/packages/ir_receiver.yaml
# Change: http://hifiberry.local:8089 → http://192.168.1.X:8089
```

### 3. Restart Home Assistant

After updating the configuration, restart Home Assistant to apply changes.

## Changes Made

### Timeouts
- **Before:** 10 seconds
- **After:** 15 seconds
- **Reason:** Some networks/devices need more time to respond

### Sensor Polling
- **Before:** 60 seconds (1 minute)
- **After:** 120 seconds (2 minutes)
- **Reason:** Reduces load on HiFiBerry device and network

### Availability Template
- **Before:** `availability_template: "{{ value_json is defined ... }}"`
- **After:** REMOVED
- **Reason:** Not supported in all Home Assistant versions, causes config errors

### Error Handling
- Still using `default('Unknown')` filter in `value_template` for graceful error handling

## Why This Happens

1. **Timeouts:** HiFiBerry device may be busy processing other requests, slower network
2. **Config Errors:** `availability_template` was added in newer HA versions, not universally available
3. **Sensor Issues:** Combination of timeout and invalid config prevents sensor from working

## Testing

After applying fixes:

```bash
# Test from Home Assistant Developer Tools
# Go to: Developer Tools → Services
# Call: rest_command.ir_receiver_power
# Should work without timeout error
```

## Optional: Use IP Address Instead of Hostname

If you still experience issues:

1. Find your HiFiBerry IP:
```bash
# On HiFiBerry device
hostname -I
```

2. Replace in all URLs:
```yaml
# Change from:
url: "http://hifiberry.local:8089/api/send"
# To:
url: "http://192.168.1.100:8089/api/send"  # Use your actual IP
```

## Need More Help?

See full troubleshooting guide in [HOMEASSISTANT.md](HOMEASSISTANT.md#troubleshooting)

