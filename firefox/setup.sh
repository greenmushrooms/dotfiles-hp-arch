#!/bin/bash
set -e

FIREFOX_DIR="/usr/lib/firefox"
PROFILE_DIR=$(find ~/.mozilla/firefox -maxdepth 1 -name '*.default-release' -print -quit 2>/dev/null)

# Autoconfig files (require sudo)
echo "Installing autoconfig files to $FIREFOX_DIR ..."
sudo cp firefox/autoconfig/local-settings.js "$FIREFOX_DIR/defaults/pref/local-settings.js"
sudo cp firefox/autoconfig/mozilla.cfg "$FIREFOX_DIR/mozilla.cfg"

# User profile files
if [ -z "$PROFILE_DIR" ]; then
  echo "No Firefox profile found. Start Firefox first, then re-run."
  exit 1
fi

echo "Installing user files to $PROFILE_DIR ..."
cp firefox/user.js "$PROFILE_DIR/user.js"

mkdir -p "$PROFILE_DIR/chrome"
cp firefox/userChrome.css "$PROFILE_DIR/chrome/userChrome.css"

# Tridactyl config
mkdir -p ~/.config/tridactyl
ln -sf "$(pwd)/firefox/tridactylrc" ~/.config/tridactyl/tridactylrc

# Tridactyl native messenger
if command -v curl &>/dev/null; then
  echo "Installing Tridactyl native messenger ..."
  curl -fsSL https://raw.githubusercontent.com/tridactyl/tridactyl/master/native/install.sh -o /tmp/trinativeinstall.sh
  sh /tmp/trinativeinstall.sh master
fi

echo "Done. Restart Firefox for changes to take effect."
