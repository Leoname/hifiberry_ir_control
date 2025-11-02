#!/bin/bash

echo "=== HiFiBerry OS Reboot Diagnostic ==="
echo ""
echo "Checking for causes of unexpected reboots..."
echo ""

# Check last reboot time
echo "1. Last Reboot Information:"
echo "──────────────────────────────────────"
uptime -s 2>/dev/null || echo "System uptime not available"
echo "Current uptime: $(uptime -p 2>/dev/null || uptime)"
echo ""

# Check last reboot reason
echo "2. Last Reboot Reason:"
echo "──────────────────────────────────────"
last reboot | head -5 2>/dev/null || echo "Reboot history not available"
echo ""

# Check kernel messages for crashes/panics
echo "3. Recent Kernel Messages (crashes, panics, oops):"
echo "──────────────────────────────────────"
dmesg | grep -i "panic\|oops\|crash\|segfault\|killed\|oom" | tail -10 || echo "No critical kernel messages"
echo ""

# Check system logs for reboot triggers
echo "4. System Log - Reboot/Shutdown Events:"
echo "──────────────────────────────────────"
if command -v journalctl &> /dev/null; then
    echo "Recent shutdown/reboot messages:"
    journalctl -b -1 -n 20 | grep -i "reboot\|shutdown\|restart" || echo "No recent reboot messages"
    echo ""
    echo "Last boot messages:"
    journalctl -b 0 | head -30
else
    echo "journalctl not available, checking syslog..."
    grep -i "reboot\|shutdown" /var/log/syslog 2>/dev/null | tail -10 || echo "No syslog available"
fi
echo ""

# Check for watchdog
echo "5. Watchdog Status:"
echo "──────────────────────────────────────"
if [ -e /dev/watchdog ]; then
    echo "✓ Watchdog device found at /dev/watchdog"
    systemctl status watchdog 2>/dev/null || echo "Watchdog service status unknown"
else
    echo "No watchdog device found"
fi
echo ""

# Check scheduled reboots (cron)
echo "6. Scheduled Tasks (cron jobs that might reboot):"
echo "──────────────────────────────────────"
crontab -l 2>/dev/null | grep -i "reboot\|shutdown" || echo "No scheduled reboot tasks in user crontab"
if [ -f /etc/crontab ]; then
    grep -i "reboot\|shutdown" /etc/crontab || echo "No scheduled reboots in /etc/crontab"
fi
echo ""

# Check systemd timers
echo "7. Systemd Timers:"
echo "──────────────────────────────────────"
if command -v systemctl &> /dev/null; then
    systemctl list-timers --all | grep -i "reboot\|shutdown" || echo "No reboot-related timers"
else
    echo "systemctl not available"
fi
echo ""

# Check running services that might cause reboots
echo "8. Services That Might Cause Reboots:"
echo "──────────────────────────────────────"
if command -v systemctl &> /dev/null; then
    echo "Checking for update/maintenance services..."
    systemctl list-units --type=service | grep -i "update\|upgrade\|maintenance" || echo "No obvious maintenance services"
else
    ps aux | grep -i "update\|upgrade" | grep -v grep || echo "No update processes"
fi
echo ""

# Check temperature (overheating can cause reboots)
echo "9. System Temperature:"
echo "──────────────────────────────────────"
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    temp=$(cat /sys/class/thermal/thermal_zone0/temp)
    temp_c=$((temp / 1000))
    echo "CPU Temperature: ${temp_c}°C"
    if [ $temp_c -gt 80 ]; then
        echo "⚠️  WARNING: Temperature is high! May cause thermal shutdowns."
    elif [ $temp_c -gt 70 ]; then
        echo "⚠️  CAUTION: Temperature is elevated."
    else
        echo "✓ Temperature is normal"
    fi
else
    echo "Temperature sensor not available"
fi
echo ""

# Check power supply issues (under-voltage)
echo "10. Power Supply Issues (throttling/under-voltage):"
echo "──────────────────────────────────────"
if command -v vcgencmd &> /dev/null; then
    throttled=$(vcgencmd get_throttled)
    echo "Throttle status: $throttled"
    if [[ "$throttled" == *"throttled=0x0"* ]]; then
        echo "✓ No throttling detected"
    else
        echo "⚠️  WARNING: System has been throttled (likely power supply issue)"
        echo "   This can cause instability and reboots!"
    fi
else
    echo "vcgencmd not available"
fi
echo ""

# Check our services
echo "11. IR Remote Control Services Status:"
echo "──────────────────────────────────────"
if command -v systemctl &> /dev/null; then
    if systemctl list-units | grep -q "ir-api"; then
        systemctl status ir-api.service --no-pager || true
    else
        echo "ir-api service not found"
    fi
else
    if [ -f /etc/init.d/ir-api ]; then
        /etc/init.d/ir-api status || true
    else
        echo "ir-api service not installed"
    fi
fi
echo ""

# Check disk space
echo "12. Disk Space (full disk can cause issues):"
echo "──────────────────────────────────────"
df -h / /boot 2>/dev/null || df -h
echo ""

# Check memory
echo "13. Memory Usage:"
echo "──────────────────────────────────────"
free -h
echo ""

# Recent bash history for manual reboot commands
echo "14. Recent Commands (checking for manual reboots):"
echo "──────────────────────────────────────"
if [ -f ~/.bash_history ]; then
    grep -i "reboot\|shutdown\|init 6" ~/.bash_history | tail -5 || echo "No recent reboot commands in history"
else
    echo "No bash history available"
fi
echo ""

echo "=== Diagnostic Complete ==="
echo ""
echo "Common Causes of Unexpected Reboots:"
echo "1. Power supply issues (most common) - Check throttling above"
echo "2. Overheating - Check temperature above"
echo "3. Kernel panics - Check kernel messages above"
echo "4. Watchdog timer - Check watchdog status above"
echo "5. Automatic updates - Check scheduled tasks above"
echo "6. Memory issues - Check memory usage above"
echo ""
echo "Recommendations:"
echo "- If throttled: Use better power supply (5V 3A recommended)"
echo "- If hot: Add cooling (heatsink or fan)"
echo "- If kernel panics: Check hardware/RAM"
echo "- Check logs: journalctl -b -1 (previous boot)"

