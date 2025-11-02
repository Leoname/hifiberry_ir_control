# Install IR Remote Control from GitHub

Quick guide to install directly from the GitHub repository.

## 🚀 **One-Line Installation**

```bash
ssh root@<hifiberry-ip> "cd /tmp && git clone https://github.com/Leoname/hifiberry_ir_control.git && cd hifiberry_ir_control && chmod +x install.sh && ./install.sh"
```

Replace `<hifiberry-ip>` with your HiFiBerry's IP address (e.g., `hifiberry.local` or `192.168.1.100`)

---

## 📋 **Step-by-Step Installation**

### Step 1: SSH into HiFiBerry OS

```bash
ssh root@<hifiberry-ip>
```

Default password is usually blank or documented in HiFiBerry OS.

### Step 2: Clone the Repository

```bash
cd /tmp
git clone https://github.com/Leoname/hifiberry_ir_control.git
cd hifiberry_ir_control
```

### Step 3: Run the Installer

```bash
chmod +x install.sh
./install.sh
```

The installer will:
- ✅ Check IR transmitter configuration (GPIO 17 by default)
- ✅ Install scripts to `/opt/hifiberry/ir-remote-control/`
- ✅ Install Beocreate web extension
- ✅ Set up and start API service
- ✅ Restart Beocreate to load extension

### Step 4: Reboot (if needed)

If this is your first time setting up IR, you'll need to reboot:

```bash
reboot
```

After reboot, run the install again to complete setup:

```bash
cd /tmp/hifiberry_ir_control
./install.sh
```

---

## 🔧 **If Git is Not Available**

HiFiBerry OS should have git, but if not:

### Option A: Install git (if package manager available)

```bash
apt-get update && apt-get install -y git
# or
opkg update && opkg install git
```

### Option B: Download ZIP

```bash
# On your computer
wget https://github.com/Leoname/hifiberry_ir_control/archive/refs/heads/main.zip
unzip main.zip
scp -r hifiberry_ir_control-main root@<hifiberry-ip>:/tmp/hifiberry_ir_control

# Then SSH in and install
ssh root@<hifiberry-ip>
cd /tmp/hifiberry_ir_control
chmod +x install.sh
./install.sh
```

---

## ⚡ **Quick Test After Installation**

```bash
# Test IR transmission
python3 /opt/hifiberry/ir-remote-control/remote_control.py -c power

# Check service status
systemctl status ir-api.service

# Access web interface
# Open: http://<hifiberry-ip>
# Navigate to: Extensions → IR Remote Control
```

---

## 🔄 **Update to Latest Version**

```bash
cd /tmp
rm -rf hifiberry_ir_control  # Remove old version
git clone https://github.com/Leoname/hifiberry_ir_control.git
cd hifiberry_ir_control
chmod +x install.sh
./install.sh
```

Or use the uninstall/reinstall method:

```bash
# Uninstall old version
cd /tmp/hifiberry_ir_control
./uninstall.sh -y

# Clone and install new version
cd /tmp
rm -rf hifiberry_ir_control
git clone https://github.com/Leoname/hifiberry_ir_control.git
cd hifiberry_ir_control
./install.sh
```

---

## 🆘 **Troubleshooting**

### "git: command not found"

Try:
```bash
which git
# If not found, try installing
apt-get install git || opkg install git
```

### "Permission denied"

Make sure you're running as root:
```bash
whoami  # Should output: root
```

If not root:
```bash
sudo su -
# Then try installation again
```

### "Repository not found"

Check your internet connection:
```bash
ping -c 3 github.com
```

---

## 📖 **Next Steps**

After successful installation:

1. **Test IR commands** - See [QUICKSTART.md](QUICKSTART.md)
2. **Configure for your receiver** - Edit IR codes if needed
3. **Optional: Install audiocontrol2 integration** - See [audiocontrol2_integration/](audiocontrol2_integration/)

---

## 🔗 **Repository**

GitHub: https://github.com/Leoname/hifiberry_ir_control

**Issues/Support:** https://github.com/Leoname/hifiberry_ir_control/issues

---

**Happy remote controlling!** 🎵📡

