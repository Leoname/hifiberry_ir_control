#!/bin/bash

echo "=== HiFiBerry OS Emergency Recovery ==="
echo ""
echo "This script will attempt to restore HiFiBerry OS functionality"
echo ""

read -p "Continue with recovery? (y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted"
    exit 0
fi

echo ""
echo "Step 1: Stopping our services..."
systemctl stop ir-api 2>/dev/null || /etc/init.d/ir-api stop 2>/dev/null || echo "IR API not running"

echo ""
echo "Step 2: Restarting Beocreate2..."
if command -v systemctl &> /dev/null; then
    systemctl restart beocreate2
    sleep 3
    if systemctl is-active --quiet beocreate2; then
        echo "✓ Beocreate2 restarted successfully"
    else
        echo "✗ Beocreate2 failed to start"
        echo "Checking logs..."
        journalctl -u beocreate2 -n 20 --no-pager
    fi
else
    /etc/init.d/beocreate2 restart
fi

echo ""
echo "Step 3: Checking web interface..."
sleep 2
if curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null | grep -q "200\|301\|302"; then
    echo "✓ Web interface is responding"
else
    echo "✗ Web interface still not responding"
fi

echo ""
echo "Step 4: Checking audiocontrol2..."
if command -v systemctl &> /dev/null; then
    if systemctl list-units | grep -q audiocontrol2; then
        systemctl restart audiocontrol2 2>/dev/null
        echo "✓ Audiocontrol2 restarted"
    else
        echo "Audiocontrol2 not installed"
    fi
fi

echo ""
echo "=== Recovery Actions Complete ==="
echo ""
echo "Current status:"
systemctl status beocreate2 --no-pager 2>/dev/null || /etc/init.d/beocreate2 status

echo ""
echo "If still not working, you may need to:"
echo "  1) Completely uninstall IR plugin: ./uninstall.sh"
echo "  2) Reboot the system: reboot"
echo "  3) Check HiFiBerry OS logs: journalctl -xe"
echo ""
read -p "Uninstall IR Remote Control plugin now? (y/n): " uninstall
if [ "$uninstall" = "y" ] || [ "$uninstall" = "Y" ]; then
    if [ -f ./uninstall.sh ]; then
        echo "Running uninstall..."
        ./uninstall.sh -y
    else
        echo "Uninstall script not found"
        echo "Manual uninstall:"
        echo "  1) systemctl stop ir-api && systemctl disable ir-api"
        echo "  2) rm -rf /opt/hifiberry/ir-remote-control"
        echo "  3) rm -rf /opt/beocreate/beo-extensions/ir-remote-control"
        echo "  4) rm /etc/systemd/system/ir-api.service"
        echo "  5) systemctl daemon-reload"
        echo "  6) systemctl restart beocreate2"
    fi
fi

