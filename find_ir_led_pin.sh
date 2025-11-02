#!/bin/bash

echo "=== Finding IR LED GPIO Pin ==="
echo ""
echo "This script will test each GPIO pin by sending a POWER command to your receiver."
echo "Make sure your receiver is ON and visible before starting."
echo ""
echo "We'll test each pin and you tell us if the receiver responded."
echo ""

# All usable GPIO pins on Raspberry Pi (excluding special function pins that shouldn't be used)
# GPIO 12, 13, 18, 19 support hardware PWM (better for IR)
# Excluding: GPIO 0, 1 (reserved), GPIO 28-45 (internal/not available on headers)
TEST_PINS=(
    2 3 4          # General purpose (2,3 are I2C but can be used)
    5 6 7 8        # General purpose (7,8 are SPI but can be used)
    9 10 11        # General purpose (SPI pins but can be used)
    12 13          # Hardware PWM capable ⭐
    14 15          # General purpose (UART but can be used)
    16 17 18       # GPIO 18 has hardware PWM ⭐
    19 20 21       # General purpose (GPIO 19 has hardware PWM ⭐)
    22 23 24 25    # General purpose
    26 27          # General purpose
)

echo "Testing ${#TEST_PINS[@]} GPIO pins..."
echo ""
echo "📌 Hardware PWM pins (recommended for best performance):"
echo "   GPIO 12 (Physical Pin 32)"
echo "   GPIO 13 (Physical Pin 33)"
echo "   GPIO 18 (Physical Pin 12) ⭐ Most common"
echo "   GPIO 19 (Physical Pin 35)"
echo ""
echo "Quick reference for common pins:"
echo "   GPIO 17 (Pin 11), GPIO 22 (Pin 15), GPIO 23 (Pin 16)"
echo "   GPIO 24 (Pin 18), GPIO 25 (Pin 22), GPIO 27 (Pin 13)"
echo ""
echo "Choose testing mode:"
echo "  1) Quick test - Hardware PWM pins only (recommended, ~2 minutes)"
echo "  2) Full test - All GPIO pins (~10-15 minutes)"
echo ""
read -p "Enter choice (1 or 2): " choice

if [ "$choice" = "1" ]; then
    TEST_PINS=(12 13 18 19)
    echo ""
    echo "✓ Quick mode: Testing 4 hardware PWM pins"
else
    echo ""
    echo "✓ Full mode: Testing ${#TEST_PINS[@]} GPIO pins"
fi

echo ""
echo "⚠️  Press Ctrl+C at any time to stop"
echo ""
echo "Press ENTER to start testing..."
read

TOTAL_PINS=${#TEST_PINS[@]}
CURRENT=0

for pin in "${TEST_PINS[@]}"; do
    CURRENT=$((CURRENT + 1))
    echo ""
    echo "=========================================="
    echo "Testing GPIO $pin (Pin $CURRENT of $TOTAL_PINS)"
    echo "=========================================="
    
    # Update the overlay configuration temporarily
    echo "Configuring IR transmitter for GPIO $pin..."
    mount -o remount,rw /boot
    
    # Backup current config
    if [ ! -f /boot/config.txt.backup ]; then
        cp /boot/config.txt /boot/config.txt.backup
    fi
    
    # Update or add the overlay
    if grep -q "dtoverlay=gpio-ir-tx" /boot/config.txt; then
        sed -i "s/dtoverlay=gpio-ir-tx.*/dtoverlay=gpio-ir-tx,gpio_pin=$pin/" /boot/config.txt
    else
        echo "dtoverlay=gpio-ir-tx,gpio_pin=$pin" >> /boot/config.txt
    fi
    
    mount -o remount,ro /boot
    
    # Load the module (remove and re-add)
    echo "Loading IR transmitter on GPIO $pin..."
    
    # Remove existing overlay
    dtoverlay -r gpio-ir-tx 2>/dev/null
    sleep 0.5
    
    # Add overlay with new pin
    dtoverlay gpio-ir-tx gpio_pin=$pin 2>/dev/null
    sleep 1
    
    # Check if device exists
    if [ ! -e /dev/lirc0 ]; then
        echo "✗ Failed to create /dev/lirc0 on GPIO $pin"
        echo "Skipping..."
        continue
    fi
    
    echo "✓ IR device ready on GPIO $pin"
    echo ""
    echo "Sending POWER command to receiver..."
    echo "Watch your receiver - it should turn OFF if this is the correct pin."
    echo ""
    
    # Send the power command
    ir-ctl -d /dev/lirc0 -S necx:0xd26d04
    
    sleep 1
    
    echo ""
    echo "Did your receiver respond (turn off)? (y/n/retry)"
    read -r response
    
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        echo ""
        echo "✓✓✓ FOUND IT! IR LED is on GPIO $pin ✓✓✓"
        echo ""
        echo "Updating /boot/config.txt with the correct pin..."
        mount -o remount,rw /boot
        sed -i "s/dtoverlay=gpio-ir-tx.*/dtoverlay=gpio-ir-tx,gpio_pin=$pin/" /boot/config.txt
        mount -o remount,ro /boot
        echo ""
        echo "Configuration saved!"
        echo "Current IR config:"
        grep "gpio-ir" /boot/config.txt
        echo ""
        echo "You can now use: python3 remote_control.py -c power"
        exit 0
    elif [ "$response" = "retry" ] || [ "$response" = "r" ]; then
        echo "Retrying GPIO $pin..."
        echo "Sending command again..."
        ir-ctl -d /dev/lirc0 -S necx:0xd26d04
        sleep 1
        echo "Did it work this time? (y/n)"
        read -r response2
        if [ "$response2" = "y" ] || [ "$response2" = "Y" ]; then
            echo ""
            echo "✓✓✓ FOUND IT! IR LED is on GPIO $pin ✓✓✓"
            mount -o remount,rw /boot
            sed -i "s/dtoverlay=gpio-ir-tx.*/dtoverlay=gpio-ir-tx,gpio_pin=$pin/" /boot/config.txt
            mount -o remount,ro /boot
            echo "Configuration saved!"
            exit 0
        fi
    fi
    
    echo "Moving to next pin..."
done

echo ""
echo "=========================================="
echo "Tested all common pins without success."
echo ""
echo "Possible issues:"
echo "1. IR LED not connected properly"
echo "2. Wrong IR codes for your receiver model"
echo "3. IR LED connected to a different GPIO pin"
echo ""
echo "Restoring original config..."
if [ -f /boot/config.txt.backup ]; then
    mount -o remount,rw /boot
    mv /boot/config.txt.backup /boot/config.txt
    mount -o remount,ro /boot
fi

