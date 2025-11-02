#!/bin/bash

echo "=========================================="
echo "Install IR Remote Controller for audiocontrol2"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run as root"
    exit 1
fi

# Configuration
AUDIOCONTROL2_DIR="/opt/hifiberry/audiocontrol2"
CONTROLLERS_DIR="$AUDIOCONTROL2_DIR/ac2/controllers"
CONFIG_DIR="$AUDIOCONTROL2_DIR/config"

echo "Step 1: Checking audiocontrol2 installation..."

if [ ! -d "$AUDIOCONTROL2_DIR" ]; then
    echo "✗ audiocontrol2 not found at $AUDIOCONTROL2_DIR"
    echo ""
    echo "audiocontrol2 may not be installed or may be in a different location."
    echo "Please check your HiFiBerry OS installation."
    echo ""
    echo "Common locations:"
    echo "  - /opt/hifiberry/audiocontrol2"
    echo "  - /usr/local/lib/python*/site-packages/audiocontrol2"
    echo ""
    read -p "Enter audiocontrol2 path (or press Enter to skip): " CUSTOM_PATH
    
    if [ -n "$CUSTOM_PATH" ] && [ -d "$CUSTOM_PATH" ]; then
        AUDIOCONTROL2_DIR="$CUSTOM_PATH"
        CONTROLLERS_DIR="$AUDIOCONTROL2_DIR/ac2/controllers"
        CONFIG_DIR="$AUDIOCONTROL2_DIR/config"
    else
        echo "Skipping audiocontrol2 integration."
        echo "The standalone API server will still work on port 8089."
        exit 0
    fi
fi

echo "✓ Found audiocontrol2 at: $AUDIOCONTROL2_DIR"
echo ""

echo "Step 2: Installing IR Remote Controller..."

# Create controllers directory if it doesn't exist
mkdir -p "$CONTROLLERS_DIR"

# Copy controller file
cp ir_remote_controller.py "$CONTROLLERS_DIR/"
chmod 644 "$CONTROLLERS_DIR/ir_remote_controller.py"

echo "✓ Controller installed to: $CONTROLLERS_DIR/ir_remote_controller.py"
echo ""

echo "Step 3: Installing configuration..."

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

# Copy config file
cp ir_remote.conf "$CONFIG_DIR/"
chmod 644 "$CONFIG_DIR/ir_remote.conf"

echo "✓ Configuration installed to: $CONFIG_DIR/ir_remote.conf"
echo ""

echo "Step 4: Registering controller with audiocontrol2..."

# Check if audiocontrol2 has a controllers config file
CONTROLLERS_CONF="$CONFIG_DIR/controllers.conf"

if [ -f "$CONTROLLERS_CONF" ]; then
    # Add IR remote controller if not already present
    if ! grep -q "ir_remote" "$CONTROLLERS_CONF"; then
        echo "" >> "$CONTROLLERS_CONF"
        echo "# IR Remote Controller" >> "$CONTROLLERS_CONF"
        echo "ir_remote = ac2.controllers.ir_remote_controller" >> "$CONTROLLERS_CONF"
        echo "✓ Added IR remote controller to controllers.conf"
    else
        echo "✓ IR remote controller already registered"
    fi
else
    echo "⚠️  controllers.conf not found"
    echo "   You may need to manually register the controller"
    echo "   Add to your audiocontrol2 configuration:"
    echo "   ir_remote = ac2.controllers.ir_remote_controller"
fi

echo ""
echo "Step 5: Restarting audiocontrol2..."

if command -v systemctl &> /dev/null && systemctl is-active --quiet audiocontrol2; then
    systemctl restart audiocontrol2
    sleep 2
    systemctl status audiocontrol2 --no-pager || true
    echo "✓ audiocontrol2 restarted"
elif [ -f /etc/init.d/audiocontrol2 ]; then
    /etc/init.d/audiocontrol2 restart
    echo "✓ audiocontrol2 restarted"
else
    echo "⚠️  Could not restart audiocontrol2 automatically"
    echo "   Please restart it manually"
fi

echo ""
echo "=========================================="
echo "✓ audiocontrol2 Integration Complete!"
echo "=========================================="
echo ""
echo "Your IR remote commands are now available through the HiFiBerry API!"
echo ""
echo "API Endpoints (assuming audiocontrol2 runs on port 81):"
echo ""
echo "Send command:"
echo "  curl -X POST http://localhost:81/api/ir_remote/send \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"command\":\"power\"}'"
echo ""
echo "Get status:"
echo "  curl http://localhost:81/api/ir_remote/status"
echo ""
echo "List commands:"
echo "  curl http://localhost:81/api/ir_remote/commands"
echo ""
echo "Volume control:"
echo "  curl -X POST http://localhost:81/api/ir_remote/volume_up"
echo "  curl -X POST http://localhost:81/api/ir_remote/volume_down"
echo ""
echo "Mute:"
echo "  curl -X POST http://localhost:81/api/ir_remote/mute"
echo ""
echo "Note: The standalone API server on port 8089 will continue to work independently."
echo ""

