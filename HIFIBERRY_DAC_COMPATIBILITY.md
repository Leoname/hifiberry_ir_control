# HiFiBerry DAC Compatibility Guide

## ⚠️ Critical Information for HiFiBerry DAC Users

If you're using a HiFiBerry DAC board (DAC+, DAC2 HD, DAC+ Pro, etc.), you **MUST** be careful about which GPIO pin you use for IR transmission.

## 🚫 **DO NOT USE These GPIO Pins**

HiFiBerry DACs use I2S (Inter-IC Sound) for audio, which requires these specific GPIO pins:

| GPIO | Function | Why You Can't Use It |
|------|----------|---------------------|
| **GPIO 18** | PCM_CLK (Bit Clock) | **WILL CAUSE REBOOTS/CRASHES** |
| **GPIO 19** | PCM_FS (Frame Sync) | Audio glitches/dropouts |
| **GPIO 20** | PCM_DIN (Data In) | Audio failure |
| **GPIO 21** | PCM_DOUT (Data Out) | Audio failure |

### What Happens If You Use GPIO 18-21?

- ✗ System reboots randomly
- ✗ Audio stops working
- ✗ Kernel panics
- ✗ HiFiBerry OS becomes unstable
- ✗ IR transmission may work but audio won't

**This was discovered during testing - GPIO 18 caused constant reboots!**

## ✅ **Safe GPIO Pins for HiFiBerry DAC + IR**

### **Recommended Pins (Hardware PWM):**

| GPIO | Physical Pin | Notes |
|------|--------------|-------|
| **GPIO 12** | Pin 32 | Hardware PWM ⭐ Best performance |
| **GPIO 13** | Pin 33 | Hardware PWM ⭐ Best performance |

### **Good Alternative Pins:**

| GPIO | Physical Pin | Notes |
|------|--------------|-------|
| **GPIO 17** | Pin 11 | **Default in this plugin** ✅ |
| GPIO 22 | Pin 15 | General purpose |
| GPIO 23 | Pin 16 | General purpose |
| GPIO 24 | Pin 18 | General purpose |
| GPIO 25 | Pin 22 | General purpose |
| GPIO 27 | Pin 13 | General purpose |

## 🔧 **Configuration**

### Default Configuration (GPIO 17)

The install script defaults to **GPIO 17**, which is safe for all HiFiBerry DACs:

```bash
dtoverlay=gpio-ir-tx,gpio_pin=17
```

### Change to Hardware PWM (GPIO 12)

For best IR performance with HiFiBerry DAC:

```bash
mount -o remount,rw /boot
nano /boot/config.txt

# Change to:
dtoverlay=gpio-ir-tx,gpio_pin=12

mount -o remount,ro /boot
reboot
```

## 🧪 **Testing Compatibility**

After configuring IR:

1. **Test IR works:**
   ```bash
   ir-ctl -d /dev/lirc0 -S necx:0xd26d04
   ```

2. **Test audio works:**
   - Play music through HiFiBerry OS
   - Check for dropouts or glitches
   - Monitor system stability

3. **Check for conflicts:**
   ```bash
   dmesg | grep -i "gpio\|i2s\|error"
   ```

If you see errors about GPIO conflicts, you're using a conflicting pin!

## 📊 **HiFiBerry DAC Models**

This applies to ALL HiFiBerry DAC models:

- HiFiBerry DAC+ (all versions)
- HiFiBerry DAC2 HD
- HiFiBerry DAC+ Pro
- HiFiBerry DAC+ DSP
- HiFiBerry DAC Zero
- HiFiBerry DAC+ ADC
- HiFiBerry DAC+ RTC

**ALL use I2S on GPIO 18-21!**

## 🐛 **Troubleshooting**

### Symptom: Random Reboots

**Cause:** IR overlay on GPIO 18-21 conflicting with I2S audio

**Fix:**
```bash
# Remove IR config
mount -o remount,rw /boot
sed -i '/dtoverlay=gpio-ir-tx/d' /boot/config.txt
mount -o remount,ro /boot
reboot

# After reboot, configure with safe pin
mount -o remount,rw /boot
echo "dtoverlay=gpio-ir-tx,gpio_pin=17" >> /boot/config.txt
mount -o remount,ro /boot
reboot
```

### Symptom: Audio Dropouts/Glitches

**Cause:** IR transmission interfering with I2S

**Fix:** Use hardware PWM pin (GPIO 12 or 13) for cleaner IR signal

### Symptom: No Audio

**Cause:** IR overlay completely blocking I2S

**Fix:** Remove IR config and use safe pin (see above)

## 📚 **Technical Details**

### I2S Protocol

HiFiBerry DACs use the I2S (Inter-IC Sound) protocol for digital audio:

```
GPIO 18 (PCM_CLK)  → Bit clock (BCLK)
GPIO 19 (PCM_FS)   → Frame sync (LRCLK/WS)
GPIO 20 (PCM_DIN)  → Data input
GPIO 21 (PCM_DOUT) → Data output
```

### Why GPIO 18 is the Worst

GPIO 18 carries the **bit clock**, which synchronizes all I2S communication. Using it for IR transmission causes:
- Clock signal corruption
- I2S driver crashes
- Kernel panic
- Immediate system instability

This is why you experienced reboots specifically with GPIO 18!

### Why Hardware PWM is Better

GPIO 12 and 13 support hardware PWM (Pulse Width Modulation):
- More precise timing for IR signals
- Less CPU overhead
- Cleaner signals
- No conflicts with audio

## ✅ **Recommended Setup**

For optimal performance with HiFiBerry DAC:

```bash
# Hardware PWM for best IR performance
dtoverlay=gpio-ir-tx,gpio_pin=12

# Or use the safe default
dtoverlay=gpio-ir-tx,gpio_pin=17
```

**Wiring:**
```
IR LED Anode (+) ──[220Ω]── GPIO 12 or 17
IR LED Cathode (-)────────── GND
```

## 📖 **References**

- [Raspberry Pi GPIO Pinout](https://pinout.xyz/)
- [HiFiBerry DAC Documentation](https://www.hifiberry.com/docs/)
- [I2S Protocol on Raspberry Pi](https://www.kernel.org/doc/html/latest/sound/soc/dai/i2s.html)

---

**Summary: Always use GPIO 17 (default) or GPIO 12/13 (hardware PWM) with HiFiBerry DACs. Never use GPIO 18-21!**

