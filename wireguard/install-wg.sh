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

# Re-running against the installed config is how you pick up new hooks
# without a fresh export from the UDM -- it must not copy a file onto itself.
if [[ $SRC -ef $DST ]]; then
    echo "source is already $DST, patching in place"
else
    install -m 600 -o root -g root "$SRC" "$DST"
fi

# The UDM omits this. Without it the tunnel goes idle behind NAT and the
# return path stops working once the router drops the mapping.
if ! grep -q '^PersistentKeepalive' "$DST"; then
    printf 'PersistentKeepalive = 25\n' >> "$DST"
    echo "added PersistentKeepalive = 25"
fi

# ── 1b. Route the home LAN over the tunnel ──────────────────────────
# The endpoint is your own WAN, so this tunnel gets used from other people's
# networks -- and plenty of them hand out 192.168.1.0/24, the same range the
# UDM serves. wg-quick's killswitch does not cover that overlap: it only
# suppresses default routes ("suppress_prefixlength 0"), so the local on-link
# /24 still wins and every home host looks like a neighbour that never
# answers ARP. wg-lan-route puts the LAN on wg0 at metric 0 and keeps exactly
# one host route to the local gateway, so the tunnel keeps its transport.
LAN=${WG_LAN:-192.168.1.0/24}
install -m 755 -o root -g root "$(dirname "$0")/wg-lan-route" /usr/local/bin/wg-lan-route
echo "installed /usr/local/bin/wg-lan-route"

if grep -q wg-lan-route "$DST"; then
    echo "wg-lan-route hooks already in $DST"
else
    # The hooks belong to [Interface], so they go in ahead of [Peer].
    awk -v lan="$LAN" '
        function hooks() {
            print "PostUp = /usr/local/bin/wg-lan-route up %i " lan
            print "PostDown = /usr/local/bin/wg-lan-route down %i " lan
        }
        !placed && /^\[Peer\]/ { hooks(); print ""; placed = 1 }
        { print }
        END { if (!placed) hooks() }
    ' "$DST" > "$DST.new"
    install -m 600 -o root -g root "$DST.new" "$DST"
    rm -f "$DST.new"
    echo "added wg-lan-route hooks for $LAN"
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
if [[ $SRC -ef $DST ]]; then
    echo "kept $DST (nothing extra to shred)"
else
    shred -u "$SRC" && echo "shredded $SRC"
fi

echo
echo "Done. Not enabled at boot on purpose: the endpoint is your own WAN,"
echo "so the tunnel only makes sense away from home. Start it with:"
echo "  vpn up      # or click the shield in waybar, or SUPER+SHIFT+W"
