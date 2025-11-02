#!/bin/bash

echo "=== Finding IR LED GPIO Pin ==="
echo ""
echo "This script helps you find which GPIO pin your IR LED is connected to."
echo ""

# Check what's currently configured
CURRENT_PIN=""
if grep -q "dtoverlay=gpio-ir-tx" /boot/config.txt 2>/dev/null; then
    CURRENT_PIN=$(grep "dtoverlay=gpio-ir-tx" /boot/config.txt | grep -oP 'gpio_pin=\K[0-9]+' || echo "")
fi

if [ -n "$CURRENT_PIN" ]; then
    echo "Currently configured: GPIO $CURRENT_PIN"
else
    echo "No IR transmitter configured yet."
fi

echo ""
echo "Choose testing method:"
echo "  1) Test current configuration (if /dev/lirc0 exists)"
echo "  2) Configure and test a specific GPIO pin (requires reboot)"
echo "  3) Show GPIO pin reference"
echo ""
read -p "Enter choice (1, 2, or 3): " choice

case $choice in
    1)
        # Test current configuration
        echo ""
        echo "=== Testing Current Configuration ==="
        
        if [ ! -e /dev/lirc0 ]; then
            echo "✗ Error: /dev/lirc0 not found"
            echo ""
            echo "The IR device is not available. You need to:"
            echo "  1. Configure a GPIO pin in /boot/config.txt"
            echo "  2. Reboot"
            echo "  3. Run this script again"
            exit 1
        fi
        
        echo "✓ IR device found at /dev/lirc0"
        
        if [ -n "$CURRENT_PIN" ]; then
            echo "✓ Configured for GPIO $CURRENT_PIN"
        fi
        
        echo ""
        echo "Make sure your receiver is ON and in view of the IR LED."
        echo ""
        read -p "Press ENTER to send POWER command..."
        
        echo "Sending IR command..."
        ir-ctl -d /dev/lirc0 -S necx:0xd26d04
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "Command sent successfully!"
            echo ""
            read -p "Did your receiver respond (turn off/on)? (y/n): " response
            
            if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
                echo ""
                echo "✓✓✓ SUCCESS! Your IR LED is working! ✓✓✓"
                if [ -n "$CURRENT_PIN" ]; then
                    echo "Your IR LED is connected to GPIO $CURRENT_PIN"
                fi
                echo ""
                echo "You can now use the remote control!"
            else
                echo ""
                echo "✗ Receiver didn't respond."
                echo ""
                echo "Possible issues:"
                echo "  1. IR LED connected to wrong GPIO pin"
                echo "  2. IR LED polarity reversed (anode/cathode swapped)"
                echo "  3. Wrong IR codes for your receiver model"
                echo "  4. IR LED not in line of sight with receiver"
                echo "  5. IR LED or resistor faulty"
                echo ""
                echo "Try option 2 to test a different GPIO pin."
            fi
        else
            echo "✗ Failed to send command. Check ir-ctl installation."
        fi
        ;;
        
    2)
        # Configure and test a specific pin
        echo ""
        echo "=== Configure GPIO Pin ==="
        echo ""
        echo "📌 Hardware PWM pins (recommended for best performance):"
        echo "   GPIO 12 (Physical Pin 32)"
        echo "   GPIO 13 (Physical Pin 33)"
        echo "   GPIO 18 (Physical Pin 12) ⭐ Most common"
        echo "   GPIO 19 (Physical Pin 35)"
        echo ""
        echo "Common general-purpose pins:"
        echo "   GPIO 17 (Pin 11), GPIO 22 (Pin 15), GPIO 23 (Pin 16)"
        echo "   GPIO 24 (Pin 18), GPIO 25 (Pin 22), GPIO 27 (Pin 13)"
        echo ""
        read -p "Enter GPIO pin number to test (e.g., 18): " pin
        
        if [ -z "$pin" ] || ! [[ "$pin" =~ ^[0-9]+$ ]]; then
            echo "Invalid pin number"
            exit 1
        fi
        
        echo ""
        echo "Configuring GPIO $pin..."
        
        # Backup config
        mount -o remount,rw /boot
        
        if [ ! -f /boot/config.txt.backup ]; then
            cp /boot/config.txt /boot/config.txt.backup
            echo "✓ Backed up config.txt"
        fi
        
        # Update or add overlay
        if grep -q "dtoverlay=gpio-ir-tx" /boot/config.txt; then
            sed -i "s/dtoverlay=gpio-ir-tx.*/dtoverlay=gpio-ir-tx,gpio_pin=$pin/" /boot/config.txt
            echo "✓ Updated existing overlay to GPIO $pin"
        else
            echo "" >> /boot/config.txt
            echo "# IR Transmitter" >> /boot/config.txt
            echo "dtoverlay=gpio-ir-tx,gpio_pin=$pin" >> /boot/config.txt
            echo "✓ Added overlay for GPIO $pin"
        fi
        
        mount -o remount,ro /boot
        
        echo ""
        echo "Configuration updated!"
        echo ""
        echo "Current IR config:"
        grep "gpio-ir" /boot/config.txt
        echo ""
        echo "⚠️  REBOOT REQUIRED for changes to take effect!"
        echo ""
        read -p "Reboot now? (y/n): " reboot_choice
        
        if [ "$reboot_choice" = "y" ] || [ "$reboot_choice" = "Y" ]; then
            echo "Rebooting..."
            reboot
        else
            echo ""
            echo "Please reboot manually, then run this script again with option 1 to test."
        fi
        ;;
        
    3)
        # Show reference
        echo ""
        echo "=== GPIO Pin Reference for Raspberry Pi ==="
        echo ""
        echo "Hardware PWM Capable (BEST for IR):"
        echo "  GPIO 12 → Physical Pin 32"
        echo "  GPIO 13 → Physical Pin 33"
        echo "  GPIO 18 → Physical Pin 12 ⭐ Most commonly used"
        echo "  GPIO 19 → Physical Pin 35"
        echo ""
        echo "General Purpose Pins (will work but may be less reliable):"
        echo "  GPIO 2  → Pin 3  | GPIO 3  → Pin 5  | GPIO 4  → Pin 7"
        echo "  GPIO 5  → Pin 29 | GPIO 6  → Pin 31 | GPIO 7  → Pin 26"
        echo "  GPIO 8  → Pin 24 | GPIO 9  → Pin 21 | GPIO 10 → Pin 19"
        echo "  GPIO 11 → Pin 23 | GPIO 14 → Pin 8  | GPIO 15 → Pin 10"
        echo "  GPIO 16 → Pin 36 | GPIO 17 → Pin 11 | GPIO 20 → Pin 38"
        echo "  GPIO 21 → Pin 40 | GPIO 22 → Pin 15 | GPIO 23 → Pin 16"
        echo "  GPIO 24 → Pin 18 | GPIO 25 → Pin 22 | GPIO 26 → Pin 37"
        echo "  GPIO 27 → Pin 13"
        echo ""
        echo "IR LED Wiring:"
        echo "  IR LED Anode (+) ──[220Ω resistor]── GPIO Pin"
        echo "  IR LED Cathode (-)─────────────────── GND"
        echo ""
        ;;
        
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
