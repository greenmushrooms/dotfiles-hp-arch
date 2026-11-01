#!/bin/bash
set -e

FIREFOX_DIR="/usr/lib/firefox"
MOZ_DIR="$HOME/.config/mozilla/firefox"

if pgrep -x firefox >/dev/null 2>&1; then
  echo "Firefox is running. Quit it first — it rewrites profiles.ini on exit."
  exit 1
fi

# Resolve the profile Firefox actually launches: installs.ini pins the default
# for this install, otherwise fall back to the *.default-release directory.
PROFILE_NAME=$(sed -n 's/^Default=\(.*\)$/\1/p' "$MOZ_DIR/installs.ini" 2>/dev/null | head -1)
if [ -n "$PROFILE_NAME" ] && [ -d "$MOZ_DIR/$PROFILE_NAME" ]; then
  PROFILE_DIR="$MOZ_DIR/$PROFILE_NAME"
else
  PROFILE_DIR=$(find "$MOZ_DIR" -maxdepth 1 -name '*.default-release' -print -quit 2>/dev/null)
fi

if [ -z "$PROFILE_DIR" ]; then
  echo "No Firefox profile found. Start Firefox first, then re-run."
  exit 1
fi

# Autoconfig files (require sudo)
echo "Installing autoconfig files to $FIREFOX_DIR ..."
sudo cp firefox/autoconfig/local-settings.js "$FIREFOX_DIR/defaults/pref/local-settings.js"
sudo cp firefox/autoconfig/mozilla.cfg "$FIREFOX_DIR/mozilla.cfg"

# User profile files
echo "Installing user files to $PROFILE_DIR ..."
cp firefox/user.js "$PROFILE_DIR/user.js"

mkdir -p "$PROFILE_DIR/chrome"
cp firefox/userChrome.css "$PROFILE_DIR/chrome/userChrome.css"

# Firefox 153 shows a profile selector at startup when ShowSelector=1 is set on
# the profile in profiles.ini. That flag lives outside any profile, so user.js
# cannot turn it off — clear it here.
if grep -q '^ShowSelector=1' "$MOZ_DIR/profiles.ini" 2>/dev/null; then
  echo "Disabling the startup profile selector ..."
  sed -i 's/^ShowSelector=1/ShowSelector=0/' "$MOZ_DIR/profiles.ini"
fi

# Tridactyl config
mkdir -p ~/.config/tridactyl
ln -sf "$(pwd)/firefox/tridactylrc" ~/.config/tridactyl/tridactylrc

# Tridactyl native messenger
if command -v curl &>/dev/null; then
  echo "Installing Tridactyl native messenger ..."
  curl -fsSL https://raw.githubusercontent.com/tridactyl/tridactyl/master/native/install.sh -o /tmp/trinativeinstall.sh
  sh /tmp/trinativeinstall.sh master
fi

echo "Done. Start Firefox for changes to take effect."
