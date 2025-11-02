#!/bin/bash

set -e

echo "=========================================="
echo "IR Remote Control Plugin for HiFiBerry OS"
echo "=========================================="
echo ""

# Configuration
INSTALL_DIR="/opt/hifiberry/ir-remote-control"
BEOCREATE_EXT_DIR="/opt/beocreate/beo-extensions/ir-remote-control"
GPIO_PIN=17  # Safe for HiFiBerry DACs (GPIO 18-21 are used by I2S audio!)

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run as root"
    echo "Please run: sudo $0"
    exit 1
fi

echo "Step 1: Checking IR transmitter configuration..."
echo ""

# Check if gpio-ir-tx is configured
if ! grep -q "dtoverlay=gpio-ir-tx" /boot/config.txt 2>/dev/null; then
    echo "IR transmitter not configured. Setting up GPIO IR on pin $GPIO_PIN..."
    mount -o remount,rw /boot
    echo "" >> /boot/config.txt
    echo "# IR Transmitter on GPIO $GPIO_PIN" >> /boot/config.txt
    echo "dtoverlay=gpio-ir-tx,gpio_pin=$GPIO_PIN" >> /boot/config.txt
    mount -o remount,ro /boot
    echo "✓ IR transmitter configured"
    echo ""
    echo "⚠️  IMPORTANT: You need to REBOOT before the IR transmitter will work!"
    echo "   After reboot, run this script again to complete installation."
    echo ""
    read -p "Reboot now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    else
        echo "Please reboot manually and run this script again."
        exit 0
    fi
fi

# Verify IR device exists
if [ ! -e /dev/lirc0 ]; then
    echo "✗ Error: /dev/lirc0 not found"
    echo ""
    echo "IR transmitter overlay is configured but device is not available."
    echo "This usually means you need to reboot for the overlay to take effect."
    echo ""
    read -p "Reboot now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    else
        echo "Please reboot manually and run this script again."
        exit 1
    fi
fi

echo "✓ IR transmitter is configured and /dev/lirc0 exists"
echo ""

echo "Step 2: Creating directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$BEOCREATE_EXT_DIR"
echo "✓ Directories created"
echo ""

echo "Step 3: Installing IR control script and API server..."
cp remote_control.py "$INSTALL_DIR/"
cp ir_api_server.py "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/remote_control.py"
chmod +x "$INSTALL_DIR/ir_api_server.py"
echo "✓ Scripts installed"
echo ""

echo "Step 4: Installing Beocreate extension..."
cp beocreate/beo-extensions/ir-remote-control/package.json "$BEOCREATE_EXT_DIR/"
cp beocreate/beo-extensions/ir-remote-control/index.js "$BEOCREATE_EXT_DIR/"
cp beocreate/beo-extensions/ir-remote-control/ui.html "$BEOCREATE_EXT_DIR/"
cp beocreate/beo-extensions/ir-remote-control/ui.js "$BEOCREATE_EXT_DIR/"
cp beocreate/beo-extensions/ir-remote-control/ui.css "$BEOCREATE_EXT_DIR/"
echo "✓ Beocreate extension installed"
echo ""

echo "Step 5: Setting up service..."

# Detect init system
if command -v systemctl &> /dev/null; then
    echo "Using systemd..."
    cp ir-api.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable ir-api.service
    systemctl start ir-api.service
    
    echo "✓ Service installed and started"
    echo ""
    echo "Service status:"
    systemctl status ir-api.service --no-pager || true
    
elif [ -d /etc/init.d ]; then
    echo "Using init.d (BusyBox)..."
    cp ir-api-busybox.init /etc/init.d/ir-api
    chmod +x /etc/init.d/ir-api
    
    # Try to enable service (may not work on all BusyBox systems)
    if command -v update-rc.d &> /dev/null; then
        update-rc.d ir-api defaults
    fi
    
    /etc/init.d/ir-api start
    echo "✓ Service installed and started"
    echo ""
    echo "Service status:"
    /etc/init.d/ir-api status || true
else
    echo "⚠️  Warning: Could not detect init system"
    echo "   You may need to start the API server manually:"
    echo "   python3 $INSTALL_DIR/ir_api_server.py &"
fi

echo ""
echo "Step 6: Restarting Beocreate..."

if command -v systemctl &> /dev/null && systemctl is-active --quiet beocreate2; then
    systemctl restart beocreate2
    echo "✓ Beocreate2 restarted (systemd)"
elif [ -f /etc/init.d/beocreate2 ]; then
    /etc/init.d/beocreate2 restart
    echo "✓ Beocreate2 restarted (init.d)"
else
    echo "⚠️  Could not restart Beocreate2 automatically"
    echo "   You may need to restart it manually"
fi

echo ""
echo "=========================================="
echo "✓✓✓ Installation Complete! ✓✓✓"
echo "=========================================="
echo ""
echo "Installation Details:"
echo "  - Scripts installed to: $INSTALL_DIR"
echo "  - Extension installed to: $BEOCREATE_EXT_DIR"
echo "  - API Server: http://localhost:8089"
echo "  - IR Device: /dev/lirc0 (GPIO $GPIO_PIN)"
echo ""
echo "Access the IR Remote Control interface through:"
echo "  HiFiBerry OS Web Interface → Extensions → IR Remote Control"
echo ""
echo "Test from command line:"
echo "  python3 $INSTALL_DIR/remote_control.py -c power"
echo ""
echo "View logs:"
if command -v systemctl &> /dev/null; then
    echo "  journalctl -u ir-api.service -f"
else
    echo "  tail -f /var/log/ir-api.log"
fi
echo ""
echo "Troubleshooting:"
echo "  - Check IR device: ls -la /dev/lirc0"
echo "  - Test IR transmission: ir-ctl -d /dev/lirc0 -S necx:0xd26d04"
echo "  - Check service: systemctl status ir-api.service"
echo ""

