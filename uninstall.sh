#!/bin/bash

echo "=========================================="
echo "Uninstall IR Remote Control Plugin"
echo "=========================================="
echo ""

# Configuration
INSTALL_DIR="/opt/hifiberry/ir-remote-control"
BEOCREATE_EXT_DIR="/opt/beocreate/beo-extensions/ir-remote-control"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run as root"
    echo "Please run as root user"
    exit 1
fi

# Check for -y flag (auto-confirm)
AUTO_CONFIRM=false
if [ "$1" = "-y" ] || [ "$1" = "--yes" ]; then
    AUTO_CONFIRM=true
fi

if [ "$AUTO_CONFIRM" = false ]; then
    echo "This will remove:"
    echo "  - IR Remote Control scripts from $INSTALL_DIR"
    echo "  - Beocreate extension from $BEOCREATE_EXT_DIR"
    echo "  - API service"
    echo ""
    echo "This will NOT remove:"
    echo "  - IR transmitter configuration in /boot/config.txt"
    echo "  - IR device (it will remain available)"
    echo ""
    read -p "Continue with uninstallation? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled"
        exit 0
    fi
    echo ""
fi

echo "Step 1: Stopping and removing service..."

if command -v systemctl &> /dev/null && [ -f /etc/systemd/system/ir-api.service ]; then
    echo "Stopping systemd service..."
    systemctl stop ir-api.service 2>/dev/null || true
    systemctl disable ir-api.service 2>/dev/null || true
    rm -f /etc/systemd/system/ir-api.service
    systemctl daemon-reload
    echo "✓ Systemd service removed"
elif [ -f /etc/init.d/ir-api ]; then
    echo "Stopping init.d service..."
    /etc/init.d/ir-api stop 2>/dev/null || true
    if command -v update-rc.d &> /dev/null; then
        update-rc.d -f ir-api remove 2>/dev/null || true
    fi
    rm -f /etc/init.d/ir-api
    echo "✓ Init.d service removed"
else
    echo "⚠️  No service found to remove"
fi

echo ""
echo "Step 2: Removing installed files..."

if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo "✓ Removed $INSTALL_DIR"
else
    echo "⚠️  Directory $INSTALL_DIR not found"
fi

if [ -d "$BEOCREATE_EXT_DIR" ]; then
    rm -rf "$BEOCREATE_EXT_DIR"
    echo "✓ Removed $BEOCREATE_EXT_DIR"
else
    echo "⚠️  Directory $BEOCREATE_EXT_DIR not found"
fi

echo ""
echo "Step 3: Cleaning up..."

# Remove log files
rm -f /var/log/ir-api.log
rm -f /var/run/ir-api.pid

echo "✓ Cleanup complete"
echo ""

echo "Step 4: Restarting Beocreate..."

if command -v systemctl &> /dev/null && systemctl is-active --quiet beocreate2; then
    systemctl restart beocreate2
    echo "✓ Beocreate2 restarted (systemd)"
elif [ -f /etc/init.d/beocreate2 ]; then
    /etc/init.d/beocreate2 restart
    echo "✓ Beocreate2 restarted (init.d)"
else
    echo "⚠️  Could not restart Beocreate2 automatically"
fi

echo ""
echo "=========================================="
echo "✓ Uninstallation Complete"
echo "=========================================="
echo ""
echo "The IR Remote Control plugin has been removed."
echo ""
echo "Note: The IR transmitter overlay in /boot/config.txt was NOT removed."
echo "If you want to completely remove IR support, manually remove this line:"
echo "  dtoverlay=gpio-ir-tx,gpio_pin=XX"
echo "from /boot/config.txt and reboot."
echo ""

