#!/usr/bin/env bash
# Install the Wi-Fi auto-recovery hook: wifi-up runs at boot and after every
# resume, so the radio comes back on its own instead of needing the picker.
#
#   sudo bash install-wifi.sh
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "run me with sudo" >&2; exit 1; }

SRC_DIR=$(cd "$(dirname "$0")" && pwd)

install -m 755 -o root -g root "$SRC_DIR/wifi-up"         /usr/local/bin/wifi-up
install -m 644 -o root -g root "$SRC_DIR/wifi-up.service" /etc/systemd/system/wifi-up.service
echo "installed /usr/local/bin/wifi-up and wifi-up.service"

systemctl daemon-reload

# One enable covers every [Install] target: multi-user for boot, and the four
# sleep targets for resume.
systemctl enable wifi-up.service
echo "enabled wifi-up.service"

# Prove it works now rather than at the next lid-close.
systemctl start wifi-up.service
systemctl --no-pager --lines=5 status wifi-up.service || true
