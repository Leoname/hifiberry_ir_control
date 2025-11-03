# Suppress Home Assistant Timeout Warnings

If your IR commands are working but you're still seeing timeout warnings in Home Assistant logs, you can suppress them using several methods.

## Method 1: Suppress REST Command Logs (Recommended)

Add this to your `configuration.yaml`:

```yaml
# Suppress REST command timeout warnings
logger:
  default: warning
  logs:
    homeassistant.components.rest_command: error  # Only show errors, not warnings
```

Or to completely silence REST command logs:

```yaml
logger:
  default: warning
  logs:
    homeassistant.components.rest_command: critical  # Only critical errors
```

Then restart Home Assistant.

## Method 2: Increase Timeout Even More

If commands are working but just taking longer than 15 seconds:

```yaml
rest_command:
  ir_receiver_power:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"power"}'
    timeout: 30  # Increased from 15 to 30 seconds
    verify_ssl: false
```

## Method 3: Use Scripts with Continue on Error

Wrap REST commands in scripts that continue even if they timeout:

```yaml
script:
  ir_receiver_power_silent:
    alias: "IR Power (Silent)"
    mode: queued
    sequence:
      - service: rest_command.ir_receiver_power
        continue_on_error: true  # Don't fail if timeout occurs
```

Then use the script instead of the direct REST command:

```yaml
# In automations or buttons
service: script.ir_receiver_power_silent
```

## Method 4: Suppress WebSocket API Errors

If you're seeing WebSocket API errors, add:

```yaml
logger:
  default: warning
  logs:
    homeassistant.components.rest_command: error
    homeassistant.components.websocket_api: error
    homeassistant.helpers.script: error
```

## Method 5: Use IP Address Instead of Hostname

Sometimes hostname resolution adds delay. Use the IP address:

```yaml
# Find your HiFiBerry IP first:
# ssh root@hifiberry.local "hostname -I"

rest_command:
  ir_receiver_power:
    url: "http://192.168.1.100:8089/api/send"  # Use actual IP
    # ... rest of config
```

## Complete Logger Configuration

Add all these to your `configuration.yaml` to suppress timeout-related warnings:

```yaml
logger:
  default: info
  logs:
    # Suppress REST command warnings
    homeassistant.components.rest_command: error
    
    # Suppress WebSocket API warnings
    homeassistant.components.websocket_api: error
    
    # Suppress script execution warnings
    homeassistant.helpers.script: error
    
    # Keep other logs at normal levels
    homeassistant.core: info
    homeassistant.components.automation: info
```

Then restart Home Assistant.

## Recommended Complete Solution

Use **Method 1 (Logger)** + **Method 3 (Scripts)** together:

### 1. Add to `configuration.yaml`:

```yaml
# Suppress timeout warnings
logger:
  default: info
  logs:
    homeassistant.components.rest_command: error
    homeassistant.components.websocket_api: error
    homeassistant.helpers.script: error

# Scripts that don't fail on timeout
script:
  # Power Control
  ir_power:
    alias: "IR: Power"
    mode: queued
    sequence:
      - service: rest_command.ir_receiver_power
        continue_on_error: true
        
  ir_mute:
    alias: "IR: Mute"
    mode: queued
    sequence:
      - service: rest_command.ir_receiver_mute
        continue_on_error: true
        
  # Volume Control
  ir_volume_up:
    alias: "IR: Volume Up"
    mode: queued
    sequence:
      - service: rest_command.ir_receiver_volume_up
        continue_on_error: true
        
  ir_volume_down:
    alias: "IR: Volume Down"
    mode: queued
    sequence:
      - service: rest_command.ir_receiver_volume_down
        continue_on_error: true
        
  # Input Selection
  ir_input_phono:
    alias: "IR: Phono"
    mode: queued
    sequence:
      - service: rest_command.ir_receiver_input_phono
        continue_on_error: true
        
  ir_input_cd:
    alias: "IR: CD"
    mode: queued
    sequence:
      - service: rest_command.ir_receiver_input_cd
        continue_on_error: true
```

### 2. Use Scripts in Your Automations/Buttons:

```yaml
# Instead of:
service: rest_command.ir_receiver_power

# Use:
service: script.ir_power
```

This way, commands execute without generating error logs even if they timeout.

## Why Timeouts Happen (Even When Working)

1. **Fire and Forget**: IR commands execute immediately, but HTTP response may be delayed
2. **Network Latency**: WiFi delays can cause response timeouts even if command succeeds
3. **Device Load**: HiFiBerry processing other tasks delays HTTP response
4. **Polling Conflicts**: Status sensor polling while sending commands

The command usually succeeds on the HiFiBerry side, but Home Assistant logs a timeout because it didn't get a response in time.

## Alternative: Disable Status Sensor

If you don't need real-time status monitoring, comment out the sensor to reduce load:

```yaml
# Status Sensor - Monitor last command (OPTIONAL - can be disabled)
# sensor:
#   - platform: rest
#     name: "IR Receiver Status"
#     ...
```

Commands will still work perfectly without the sensor.

## Testing

After applying logger configuration:

1. Restart Home Assistant
2. Send an IR command
3. Check logs - you should no longer see timeout warnings
4. Commands should still work normally

## Verify It's Working

Despite timeout warnings, commands should be working. Test by:

1. Send command from Home Assistant
2. Check if receiver responds (power on/off, input changes, etc.)
3. If it works, it's just a logging issue - safe to suppress

If commands actually DON'T work, see [HOMEASSISTANT.md](HOMEASSISTANT.md) for real troubleshooting.

