# Home Assistant Integration - IR Remote Control

This guide shows how to integrate the HiFiBerry IR Remote Control with Home Assistant, allowing you to control your audio receiver directly from Home Assistant.

## Overview

The IR Remote Control API runs on port 8089 and provides REST endpoints that can be easily integrated with Home Assistant using:
- **REST Commands** - Send IR commands
- **Buttons** - Trigger commands from the UI
- **Scripts** - Create command sequences (macros)
- **Automations** - Trigger based on events

## Quick Start

Add the following to your Home Assistant configuration:

### Method 1: Basic REST Commands

Add to your `configuration.yaml`:

```yaml
# REST Commands for IR Remote Control
rest_command:
  # Power and Mute
  ir_receiver_power:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"power"}'
    
  ir_receiver_mute:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"mute"}'
    
  # Volume Control
  ir_receiver_volume_up:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"volume_up"}'
    
  ir_receiver_volume_down:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"volume_down"}'
    
  # Input Selection
  ir_receiver_input_tuner:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_tuner"}'
    
  ir_receiver_input_phono:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_phono"}'
    
  ir_receiver_input_cd:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_cd"}'
    
  ir_receiver_input_direct:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_direct"}'
    
  ir_receiver_input_video1:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_video1"}'
    
  ir_receiver_input_video2:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_video2"}'
    
  ir_receiver_input_tape1:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_tape1"}'
    
  ir_receiver_input_tape2:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_tape2"}'

# Sensor to monitor IR status
sensor:
  - platform: rest
    name: "IR Receiver Status"
    resource: "http://hifiberry.local:8089/api/status"
    method: GET
    scan_interval: 30
    json_attributes:
      - last_command
      - last_status
      - timestamp
    value_template: "{{ value_json.last_status }}"
```

**Replace `hifiberry.local` with your HiFiBerry device's IP address or hostname.**

Restart Home Assistant after adding the configuration.

### Method 2: Using Buttons (Home Assistant 2023.4+)

Create buttons in your dashboard or add to `configuration.yaml`:

```yaml
# Button Entities for IR Control
button:
  - platform: template
    buttons:
      ir_receiver_power_button:
        friendly_name: "Receiver Power"
        icon_template: mdi:power
        press:
          service: rest_command.ir_receiver_power
          
      ir_receiver_mute_button:
        friendly_name: "Receiver Mute"
        icon_template: mdi:volume-mute
        press:
          service: rest_command.ir_receiver_mute
          
      ir_receiver_volume_up_button:
        friendly_name: "Volume Up"
        icon_template: mdi:volume-plus
        press:
          service: rest_command.ir_receiver_volume_up
          
      ir_receiver_volume_down_button:
        friendly_name: "Volume Down"
        icon_template: mdi:volume-minus
        press:
          service: rest_command.ir_receiver_volume_down
```

## Complete Configuration Package

For a cleaner setup, create a package file. Create a new file `packages/ir_receiver.yaml`:

```yaml
# packages/ir_receiver.yaml
# IR Remote Control Package for Home Assistant

homeassistant:
  customize:
    sensor.ir_receiver_status:
      friendly_name: "IR Receiver Status"
      icon: mdi:remote

# REST Commands
rest_command:
  ir_receiver_power:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"power"}'
    
  ir_receiver_mute:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"mute"}'
    
  ir_receiver_volume_up:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"volume_up"}'
    
  ir_receiver_volume_down:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"volume_down"}'
    
  ir_receiver_input_tuner:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_tuner"}'
    
  ir_receiver_input_phono:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_phono"}'
    
  ir_receiver_input_cd:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_cd"}'
    
  ir_receiver_input_direct:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_direct"}'
    
  ir_receiver_input_video1:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_video1"}'
    
  ir_receiver_input_video2:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_video2"}'
    
  ir_receiver_input_tape1:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_tape1"}'
    
  ir_receiver_input_tape2:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"input_tape2"}'

# Status Sensor
sensor:
  - platform: rest
    name: "IR Receiver Status"
    resource: "http://hifiberry.local:8089/api/status"
    method: GET
    scan_interval: 30
    json_attributes:
      - last_command
      - last_status
      - timestamp
    value_template: "{{ value_json.last_status }}"

# Scripts for macros
script:
  # Power on and switch to CD
  ir_receiver_power_on_cd:
    alias: "Receiver Power On + CD"
    sequence:
      - service: rest_command.ir_receiver_power
      - delay:
          seconds: 2
      - service: rest_command.ir_receiver_input_cd
      
  # Power on and switch to Phono
  ir_receiver_power_on_phono:
    alias: "Receiver Power On + Phono"
    sequence:
      - service: rest_command.ir_receiver_power
      - delay:
          seconds: 2
      - service: rest_command.ir_receiver_input_phono
      
  # Volume up 3 times
  ir_receiver_volume_up_3x:
    alias: "Volume Up 3x"
    sequence:
      - repeat:
          count: 3
          sequence:
            - service: rest_command.ir_receiver_volume_up
            - delay:
                milliseconds: 500
      
  # Volume down 3 times
  ir_receiver_volume_down_3x:
    alias: "Volume Down 3x"
    sequence:
      - repeat:
          count: 3
          sequence:
            - service: rest_command.ir_receiver_volume_down
            - delay:
                milliseconds: 500
```

## Dashboard Cards

### Basic Button Card

Add this to your Lovelace dashboard:

```yaml
type: grid
cards:
  - type: button
    name: Power
    icon: mdi:power
    tap_action:
      action: call-service
      service: rest_command.ir_receiver_power
      
  - type: button
    name: Mute
    icon: mdi:volume-mute
    tap_action:
      action: call-service
      service: rest_command.ir_receiver_mute
      
  - type: button
    name: Volume +
    icon: mdi:volume-plus
    tap_action:
      action: call-service
      service: rest_command.ir_receiver_volume_up
      
  - type: button
    name: Volume -
    icon: mdi:volume-minus
    tap_action:
      action: call-service
      service: rest_command.ir_receiver_volume_down
columns: 2
```

### Full Remote Control Card

```yaml
type: vertical-stack
cards:
  # Status Display
  - type: entity
    entity: sensor.ir_receiver_status
    
  # Power & Mute
  - type: grid
    cards:
      - type: button
        name: Power
        icon: mdi:power
        tap_action:
          action: call-service
          service: rest_command.ir_receiver_power
        hold_action:
          action: none
          
      - type: button
        name: Mute
        icon: mdi:volume-mute
        tap_action:
          action: call-service
          service: rest_command.ir_receiver_mute
    columns: 2
    
  # Volume Control
  - type: grid
    cards:
      - type: button
        name: Vol +
        icon: mdi:volume-plus
        tap_action:
          action: call-service
          service: rest_command.ir_receiver_volume_up
        hold_action:
          action: call-service
          service: script.ir_receiver_volume_up_3x
          
      - type: button
        name: Vol -
        icon: mdi:volume-minus
        tap_action:
          action: call-service
          service: rest_command.ir_receiver_volume_down
        hold_action:
          action: call-service
          service: script.ir_receiver_volume_down_3x
    columns: 2
    
  # Input Selection
  - type: grid
    cards:
      - type: button
        name: Tuner
        icon: mdi:radio
        tap_action:
          action: call-service
          service: rest_command.ir_receiver_input_tuner
          
      - type: button
        name: Phono
        icon: mdi:album
        tap_action:
          action: call-service
          service: rest_command.ir_receiver_input_phono
          
      - type: button
        name: CD
        icon: mdi:disc
        tap_action:
          action: call-service
          service: rest_command.ir_receiver_input_cd
          
      - type: button
        name: Direct
        icon: mdi:music-note
        tap_action:
          action: call-service
          service: rest_command.ir_receiver_input_direct
    columns: 2
    
  - type: grid
    cards:
      - type: button
        name: Video 1
        icon: mdi:video
        tap_action:
          action: call-service
          service: rest_command.ir_receiver_input_video1
          
      - type: button
        name: Video 2
        icon: mdi:video
        tap_action:
          action: call-service
          service: rest_command.ir_receiver_input_video2
          
      - type: button
        name: Tape 1
        icon: mdi:cassette
        tap_action:
          action: call-service
          service: rest_command.ir_receiver_input_tape1
          
      - type: button
        name: Tape 2
        icon: mdi:cassette
        tap_action:
          action: call-service
          service: rest_command.ir_receiver_input_tape2
    columns: 2
```

## Automations

### Example: Auto Power On with Music

```yaml
automation:
  - alias: "IR Receiver Auto Power On"
    trigger:
      - platform: state
        entity_id: media_player.hifiberry
        to: "playing"
    action:
      - service: rest_command.ir_receiver_power
      - delay:
          seconds: 2
      - service: rest_command.ir_receiver_input_direct
```

### Example: Auto Power Off at Night

```yaml
automation:
  - alias: "IR Receiver Auto Power Off"
    trigger:
      - platform: time
        at: "23:00:00"
    condition:
      - condition: state
        entity_id: media_player.hifiberry
        state: "idle"
    action:
      - service: rest_command.ir_receiver_power
```

### Example: Switch Input Based on Media Player

```yaml
automation:
  - alias: "IR Receiver Auto Input Switch"
    trigger:
      - platform: state
        entity_id: input_select.music_source
    action:
      - choose:
          - conditions:
              - condition: state
                entity_id: input_select.music_source
                state: "CD Player"
            sequence:
              - service: rest_command.ir_receiver_input_cd
          - conditions:
              - condition: state
                entity_id: input_select.music_source
                state: "Turntable"
            sequence:
              - service: rest_command.ir_receiver_input_phono
          - conditions:
              - condition: state
                entity_id: input_select.music_source
                state: "Tuner"
            sequence:
              - service: rest_command.ir_receiver_input_tuner
```

## Advanced: Custom Input Select

Create an input selector to switch between sources:

```yaml
# configuration.yaml
input_select:
  ir_receiver_input:
    name: Receiver Input
    options:
      - Tuner
      - Phono
      - CD
      - Direct
      - Video 1
      - Video 2
      - Tape 1
      - Tape 2
    icon: mdi:import

# Automation to send command when input changes
automation:
  - alias: "IR Receiver Input Switch"
    trigger:
      - platform: state
        entity_id: input_select.ir_receiver_input
    action:
      - choose:
          - conditions:
              - condition: state
                entity_id: input_select.ir_receiver_input
                state: "Tuner"
            sequence:
              - service: rest_command.ir_receiver_input_tuner
          - conditions:
              - condition: state
                entity_id: input_select.ir_receiver_input
                state: "Phono"
            sequence:
              - service: rest_command.ir_receiver_input_phono
          - conditions:
              - condition: state
                entity_id: input_select.ir_receiver_input
                state: "CD"
            sequence:
              - service: rest_command.ir_receiver_input_cd
          - conditions:
              - condition: state
                entity_id: input_select.ir_receiver_input
                state: "Direct"
            sequence:
              - service: rest_command.ir_receiver_input_direct
          - conditions:
              - condition: state
                entity_id: input_select.ir_receiver_input
                state: "Video 1"
            sequence:
              - service: rest_command.ir_receiver_input_video1
          - conditions:
              - condition: state
                entity_id: input_select.ir_receiver_input
                state: "Video 2"
            sequence:
              - service: rest_command.ir_receiver_input_video2
          - conditions:
              - condition: state
                entity_id: input_select.ir_receiver_input
                state: "Tape 1"
            sequence:
              - service: rest_command.ir_receiver_input_tape1
          - conditions:
              - condition: state
                entity_id: input_select.ir_receiver_input
                state: "Tape 2"
            sequence:
              - service: rest_command.ir_receiver_input_tape2
```

Then add to your dashboard:

```yaml
type: entities
entities:
  - entity: input_select.ir_receiver_input
  - entity: sensor.ir_receiver_status
```

## Testing

### Test REST Commands

After adding the configuration, test from Home Assistant Developer Tools:

1. Go to **Developer Tools** → **Services**
2. Search for `rest_command.ir_receiver_power`
3. Click **Call Service**
4. Check if your receiver responds

### Test via Command Line

You can also test the API directly:

```bash
# From any machine on your network
curl -X POST http://hifiberry.local:8089/api/send \
  -H "Content-Type: application/json" \
  -d '{"command":"power"}'
  
# Check status
curl http://hifiberry.local:8089/api/status
```

## Troubleshooting

### Commands Don't Work

1. **Check API is reachable:**
```bash
curl http://hifiberry.local:8089/api/status
```

2. **Check Home Assistant logs:**
   - Go to Settings → System → Logs
   - Look for REST command errors

3. **Verify hostname:**
   - Replace `hifiberry.local` with the actual IP address
   - Test: `ping hifiberry.local`

4. **Check firewall:**
   - Ensure port 8089 is not blocked
   - Test from Home Assistant host: `telnet hifiberry.local 8089`

### Status Sensor Shows "Unavailable"

1. **Check scan interval** - might be too frequent
2. **Verify API responds** - test with curl
3. **Check Home Assistant network** - ensure it can reach HiFiBerry device

### Slow Response

1. **Increase timeout** in REST command:
```yaml
rest_command:
  ir_receiver_power:
    url: "http://hifiberry.local:8089/api/send"
    timeout: 10  # Increased from 5
    method: POST
    # ...
```

2. **Check HiFiBerry device load** - might be overloaded

### "Empty reply found when expecting JSON data"

This error occurs when the API returns an empty response. Solutions:

1. **Reduce sensor polling frequency:**
```yaml
sensor:
  - platform: rest
    scan_interval: 60  # Increase from 30
    timeout: 10  # Increase timeout
```

2. **Update to improved API server** (v2 with threading support):
```bash
# On HiFiBerry device
cd /tmp
git clone https://github.com/Leoname/hifiberry_ir_control.git
cd hifiberry_ir_control
chmod +x install.sh
./install.sh

# Restart API service
systemctl restart ir-api.service
```

The new API server supports concurrent requests and better error handling.

### "Cannot connect to host" / "Invalid argument"

These SSL-related errors occur even though we're using HTTP. Solutions:

1. **Add `verify_ssl: false` to all REST commands:**
```yaml
rest_command:
  ir_receiver_power:
    url: "http://hifiberry.local:8089/api/send"
    method: POST
    verify_ssl: false  # Add this line
    timeout: 10
    # ...
```

2. **Use IP address instead of hostname:**
```yaml
# Replace hifiberry.local with actual IP
url: "http://192.168.1.100:8089/api/send"
```

To find your HiFiBerry IP:
```bash
# On HiFiBerry device
hostname -I

# Or from another computer
ping hifiberry.local
```

3. **Check network connectivity:**
```bash
# From Home Assistant host
ping hifiberry.local
curl http://hifiberry.local:8089/api/status
```

### "Timeout while fetching data"

The REST sensor is timing out. Solutions:

1. **Increase timeout and scan interval:**
```yaml
sensor:
  - platform: rest
    name: "IR Receiver Status"
    resource: "http://192.168.1.100:8089/api/status"  # Use IP
    scan_interval: 60  # Poll less frequently
    timeout: 10  # Longer timeout
    force_update: false  # Only update on changes
```

2. **Add availability template:**
```yaml
sensor:
  - platform: rest
    # ... other settings ...
    availability_template: "{{ value_json is defined }}"
```

3. **Consider disabling the sensor if not needed:**
   - Comment out the entire sensor section if you don't need status monitoring
   - Commands will still work without the sensor

### Recommended Complete Fix

Update your Home Assistant configuration with these improvements:

```yaml
# Improved REST commands with better error handling
rest_command:
  ir_receiver_power:
    url: "http://192.168.1.100:8089/api/send"  # Use IP instead of hostname
    method: POST
    headers:
      Content-Type: application/json
    payload: '{"command":"power"}'
    timeout: 10  # Increased timeout
    verify_ssl: false  # Disable SSL verification
    
# Improved status sensor with less aggressive polling
sensor:
  - platform: rest
    name: "IR Receiver Status"
    resource: "http://192.168.1.100:8089/api/status"
    method: GET
    scan_interval: 60  # Reduced from 30
    timeout: 10  # Increased timeout
    force_update: false  # Only update when value changes
    json_attributes:
      - last_command
      - last_status
      - timestamp
    value_template: "{{ value_json.last_status | default('Unknown') }}"
    availability_template: "{{ value_json is defined and value_json.last_status is defined }}"
```

**Note:** Replace `192.168.1.100` with your actual HiFiBerry IP address.

## Voice Control (Alexa/Google Assistant)

If you have Home Assistant integrated with Alexa or Google Assistant, you can expose the scripts:

```yaml
# configuration.yaml
alexa:
  smart_home:

# Expose scripts
script:
  ir_receiver_power_on_cd:
    # ... (from above)
    alexa:
      name: "Receiver CD Player"
      description: "Turn on receiver and switch to CD"
```

Then say: "Alexa, turn on Receiver CD Player"

## Node-RED Integration

If you use Node-RED with Home Assistant:

1. Add an **inject** node (triggers the flow)
2. Add an **http request** node:
   - Method: POST
   - URL: `http://hifiberry.local:8089/api/send`
   - Headers: `{"Content-Type": "application/json"}`
   - Payload: `{"command":"power"}`
3. Add a **debug** node to see the response

## Tips

1. **Use static IP** for HiFiBerry device to avoid hostname resolution issues
2. **Group commands** in scripts for common actions (power on + input switch)
3. **Add delays** between commands if receiver needs time to respond
4. **Monitor status sensor** to know last command sent
5. **Use hold_action** on buttons for multi-repeat commands (volume up 3x)

## Complete Example File

See the included `home_assistant_package.yaml` file for a complete, copy-paste ready configuration.

## More Information

- [Home Assistant REST Command](https://www.home-assistant.io/integrations/rest_command/)
- [Home Assistant REST Sensor](https://www.home-assistant.io/integrations/rest/)
- [Home Assistant Scripts](https://www.home-assistant.io/integrations/script/)
- [Home Assistant Automations](https://www.home-assistant.io/docs/automation/)

---

**Enjoy controlling your receiver with Home Assistant! 🏠🎵**

