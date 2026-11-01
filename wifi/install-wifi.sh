#!/usr/bin/env bash
# Install the Wi-Fi auto-recovery hook: cap iwd's reconnect backoff, and run
# wifi-up at boot and after every resume so the link comes back on its own.
#
#   sudo bash install-wifi.sh
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "run me with sudo" >&2; exit 1; }

SRC_DIR=$(cd "$(dirname "$0")" && pwd)
IWD_CONF=/etc/iwd/main.conf

install -m 755 -o root -g root "$SRC_DIR/wifi-up"         /usr/local/bin/wifi-up
install -m 644 -o root -g root "$SRC_DIR/wifi-up.service" /etc/systemd/system/wifi-up.service
echo "installed /usr/local/bin/wifi-up and wifi-up.service"

# ── Cap iwd's reconnect backoff ─────────────────────────────────────
# main.conf has no drop-in directory, so this appends to the live file rather
# than replacing it -- [General] settings there must survive.
install -d -m 755 -o root -g root /etc/iwd
touch "$IWD_CONF"

if grep -q '^\[Scan\]' "$IWD_CONF"; then
    echo "note: $IWD_CONF already has a [Scan] section, leaving it alone"
    echo "      compare against $SRC_DIR/iwd-scan.conf if reconnects are slow"
else
    cp -a "$IWD_CONF" "$IWD_CONF.bak.$(date +%s)"
    printf '\n' >> "$IWD_CONF"
    cat "$SRC_DIR/iwd-scan.conf" >> "$IWD_CONF"
    echo "added [Scan] caps to $IWD_CONF (backed up alongside)"
    # iwd reads main.conf only at startup. Restarting drops the current link
    # for a moment; wifi-up brings it straight back.
    systemctl restart iwd.service
    echo "restarted iwd.service to pick up the new scan intervals"
fi

systemctl daemon-reload

# One enable covers every [Install] target: multi-user for boot, and the four
# sleep targets for resume.
systemctl enable wifi-up.service
echo "enabled wifi-up.service"

# Prove it works now rather than at the next lid-close.
systemctl start wifi-up.service
systemctl --no-pager --lines=5 status wifi-up.service || true
