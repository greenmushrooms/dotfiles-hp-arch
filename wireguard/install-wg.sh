#!/usr/bin/env bash
# Install a WireGuard client config (e.g. one exported from the UDM) as wg0,
# with the privileges the waybar toggle and status tooltip need.
#
#   sudo bash install-wg.sh [path/to/client.conf]
#
# With no argument, picks the newest *.conf in the invoking user's Downloads.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "run me with sudo" >&2; exit 1; }

USER_NAME=${SUDO_USER:-$(logname)}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)
DST=/etc/wireguard/wg0.conf

SRC=${1:-}
if [[ -z $SRC ]]; then
    SRC=$(ls -t "$USER_HOME"/Downloads/*.conf 2>/dev/null | head -1) \
        || { echo "no .conf given and none found in $USER_HOME/Downloads" >&2; exit 1; }
    echo "using newest download: $SRC"
fi
[[ -f $SRC ]] || { echo "missing $SRC" >&2; exit 1; }

# ── 1. Install the config, root-only ────────────────────────────────
# /etc/wireguard must not be user-writable: wg-quick runs PostUp as root,
# so write access to the config is equivalent to root.
install -d -m 700 -o root -g root /etc/wireguard

if [[ -e $DST ]]; then
    cp -a "$DST" "$DST.bak.$(date +%s)"
    echo "backed up existing $DST"
fi

install -m 600 -o root -g root "$SRC" "$DST"

# The UDM omits this. Without it the tunnel goes idle behind NAT and the
# return path stops working once the router drops the mapping.
if ! grep -q '^PersistentKeepalive' "$DST"; then
    printf 'PersistentKeepalive = 25\n' >> "$DST"
    echo "added PersistentKeepalive = 25"
fi

wg-quick strip wg0 >/dev/null && echo "config parses clean"

# ── 2. Let wheel flip this one unit without a password prompt ────────
cat > /etc/polkit-1/rules.d/50-wg-quick.rules <<'RULE'
// Allow a locally logged-in wheel user to start/stop the wg0 tunnel
// without authenticating. Scoped to this single unit on purpose.
polkit.addRule(function (action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "wg-quick@wg0.service" &&
        subject.isInGroup("wheel") &&
        subject.local && subject.active) {
        return polkit.Result.YES;
    }
});
RULE
chmod 644 /etc/polkit-1/rules.d/50-wg-quick.rules
echo "polkit rule installed"

# ── 3. Read-only handshake query for the waybar tooltip ─────────────
# Exact-argument match. Exposes the peer's public key and a timestamp;
# never the private key (that would be `wg show wg0 private-key`).
SUDOERS=/etc/sudoers.d/wg-show
printf '%s ALL=(root) NOPASSWD: /usr/bin/wg show wg0 latest-handshakes\n' "$USER_NAME" > "$SUDOERS"
chmod 440 "$SUDOERS"
if visudo -cf "$SUDOERS" >/dev/null; then
    echo "sudoers rule installed"
else
    rm -f "$SUDOERS"; echo "sudoers rule rejected, removed" >&2
fi

# ── 4. Remove the world-readable copy holding the private key ───────
shred -u "$SRC" && echo "shredded $SRC"

echo
echo "Done. Not enabled at boot on purpose: the endpoint is your own WAN,"
echo "so the tunnel only makes sense away from home. Start it with:"
echo "  vpn up      # or click the shield in waybar, or SUPER+SHIFT+W"
