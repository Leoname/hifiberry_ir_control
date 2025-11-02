#!/bin/bash

echo "=== HiFiBerry OS Health Check ==="
echo ""

# Check if beocreate2 is running
echo "1. Beocreate2 Service Status:"
echo "──────────────────────────────────────"
if command -v systemctl &> /dev/null; then
    systemctl status beocreate2 --no-pager || echo "Service status check failed"
    echo ""
    if systemctl is-active --quiet beocreate2; then
        echo "✓ Beocreate2 is running"
    else
        echo "✗ Beocreate2 is NOT running!"
        echo "Attempting to start..."
        systemctl start beocreate2
        sleep 3
        if systemctl is-active --quiet beocreate2; then
            echo "✓ Successfully started beocreate2"
        else
            echo "✗ Failed to start beocreate2"
            echo "Check logs: journalctl -u beocreate2 -n 50"
        fi
    fi
else
    echo "Using init.d..."
    /etc/init.d/beocreate2 status || echo "Service not found"
fi
echo ""

# Check audiocontrol2
echo "2. Audiocontrol2 Service Status:"
echo "──────────────────────────────────────"
if command -v systemctl &> /dev/null; then
    if systemctl list-units | grep -q audiocontrol2; then
        systemctl status audiocontrol2 --no-pager || true
        if systemctl is-active --quiet audiocontrol2; then
            echo "✓ Audiocontrol2 is running"
        else
            echo "✗ Audiocontrol2 is NOT running"
        fi
    else
        echo "Audiocontrol2 not found (may be normal)"
    fi
else
    echo "systemctl not available"
fi
echo ""

# Check our IR API service
echo "3. IR API Service Status:"
echo "──────────────────────────────────────"
if command -v systemctl &> /dev/null; then
    if systemctl list-units | grep -q ir-api; then
        systemctl status ir-api --no-pager || true
        if systemctl is-active --quiet ir-api; then
            echo "✓ IR API is running"
        else
            echo "⚠️  IR API is not running (this might be okay if not started yet)"
        fi
    else
        echo "IR API service not installed yet"
    fi
fi
echo ""

# Check if web interface is accessible
echo "4. Web Interface Check:"
echo "──────────────────────────────────────"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null | grep -q "200\|301\|302"; then
    echo "✓ Web interface is responding"
else
    echo "✗ Web interface is NOT responding"
fi
echo ""

# Check beocreate extensions
echo "5. Beocreate Extensions:"
echo "──────────────────────────────────────"
if [ -d /opt/beocreate/beo-extensions ]; then
    echo "Extensions directory exists"
    ls -la /opt/beocreate/beo-extensions/ | grep -v "^total" | tail -n +2
    echo ""
    if [ -d /opt/beocreate/beo-extensions/ir-remote-control ]; then
        echo "✓ IR Remote Control extension installed"
        ls -la /opt/beocreate/beo-extensions/ir-remote-control/
    fi
else
    echo "✗ Extensions directory not found!"
fi
echo ""

# Check logs for errors
echo "6. Recent Errors in Logs:"
echo "──────────────────────────────────────"
if command -v journalctl &> /dev/null; then
    echo "Beocreate2 errors:"
    journalctl -u beocreate2 -p err -n 10 --no-pager || echo "No errors or service not found"
    echo ""
    echo "System errors:"
    journalctl -p err -n 10 --no-pager || echo "No recent errors"
else
    echo "journalctl not available, checking logs..."
    if [ -f /var/log/beocreate2.log ]; then
        tail -20 /var/log/beocreate2.log | grep -i error || echo "No errors in beocreate2.log"
    else
        echo "Log file not found"
    fi
fi
echo ""

# Check port conflicts
echo "7. Port Usage Check:"
echo "──────────────────────────────────────"
echo "Checking critical ports..."
netstat -tuln 2>/dev/null | grep -E ":(80|81|8089|3000)" || ss -tuln 2>/dev/null | grep -E ":(80|81|8089|3000)" || echo "Cannot check ports"
echo ""

# Check file permissions
echo "8. File Permissions:"
echo "──────────────────────────────────────"
if [ -d /opt/hifiberry/ir-remote-control ]; then
    ls -la /opt/hifiberry/ir-remote-control/
else
    echo "IR remote control not installed yet"
fi
echo ""

# Check for conflicting processes
echo "9. Process Check:"
echo "──────────────────────────────────────"
ps aux | grep -E "beocreate|audiocontrol|python.*ir" | grep -v grep || echo "No relevant processes found"
echo ""

echo "=== Quick Fix Options ==="
echo ""
echo "If Beocreate2 is broken, try:"
echo "  1) Restart service: systemctl restart beocreate2"
echo "  2) Check logs: journalctl -u beocreate2 -n 50"
echo "  3) Uninstall IR plugin: ./uninstall.sh"
echo ""
echo "If web interface not responding:"
echo "  1) Check if port 80 is in use"
echo "  2) Restart beocreate2"
echo "  3) Check /opt/beocreate directory permissions"
echo ""

