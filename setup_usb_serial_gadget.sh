#!/bin/bash
# Script: setup_usb_serial_gadget.sh
# Purpose: Enable USB serial gadget mode on Pi Zero 2 W, keep HDMI/keyboard, enable getty, and log all changes/results
# Usage: sudo ./setup_usb_serial_gadget.sh

set -e
LOGFILE="/home/$(whoami)/usb_gadget_setup_$(date +%Y%m%d_%H%M%S).log"

# 1. Update /boot/firmware/config.txt
CFG_FILE="/boot/firmware/config.txt"
if ! grep -q '^dtoverlay=dwc2$' "$CFG_FILE"; then
    echo "Adding dtoverlay=dwc2 to $CFG_FILE" | tee -a "$LOGFILE"
    echo 'dtoverlay=dwc2' | sudo tee -a "$CFG_FILE" | tee -a "$LOGFILE"
else
    echo "dtoverlay=dwc2 already present in $CFG_FILE" | tee -a "$LOGFILE"
fi

# 2. Update /boot/firmware/cmdline.txt
CMD_FILE="/boot/firmware/cmdline.txt"
if ! grep -q 'modules-load=dwc2,g_serial' "$CMD_FILE"; then
    echo "Adding modules-load=dwc2,g_serial to $CMD_FILE" | tee -a "$LOGFILE"
    sudo sed -i 's/rootwait/& modules-load=dwc2,g_serial console=tty1/' "$CMD_FILE"
else
    echo "modules-load=dwc2,g_serial already present in $CMD_FILE" | tee -a "$LOGFILE"
fi

# 3. Enable getty on ttyGS0
sudo systemctl enable --now serial-getty@ttyGS0.service | tee -a "$LOGFILE"
echo "Enabled serial-getty@ttyGS0.service" | tee -a "$LOGFILE"

# 4. Log htop snapshot before and after
if command -v htop &>/dev/null; then
    echo "--- htop BEFORE ---" | tee -a "$LOGFILE"
    htop -b -n 1 | tee -a "$LOGFILE"
else
    echo "htop not installed, skipping htop snapshot" | tee -a "$LOGFILE"
fi

# 5. Log dmesg, lsmod, and device status
{
    echo "--- dmesg (last 200 lines) ---"
    dmesg | tail -n 200
    echo "--- lsmod ---"
    lsmod | grep -E 'dwc2|g_serial'
    echo "--- /dev/ttyGS0 ---"
    ls -l /dev/ttyGS0 || echo "/dev/ttyGS0 not present"
    echo "--- systemctl status serial-getty@ttyGS0.service ---"
    systemctl status serial-getty@ttyGS0.service
    echo "--- /proc/cmdline ---"
    cat /proc/cmdline
} | tee -a "$LOGFILE"

# 6. Log htop snapshot after
if command -v htop &>/dev/null; then
    echo "--- htop AFTER ---" | tee -a "$LOGFILE"
    htop -b -n 1 | tee -a "$LOGFILE"
fi

echo "All changes complete. Please reboot to activate USB gadget mode." | tee -a "$LOGFILE"
echo "Log saved to $LOGFILE"
