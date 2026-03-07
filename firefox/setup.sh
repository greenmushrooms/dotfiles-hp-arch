#!/usr/bin/env bash
set -e

PROFILES_DIR="$HOME/.config/mozilla/firefox"
PROFILES_INI="$PROFILES_DIR/profiles.ini"

if [[ ! -f "$PROFILES_INI" ]]; then
  echo "Firefox profiles.ini not found, skipping."
  exit 0
fi

PROFILE_PATH=$(awk -F= '/^Default=/ { print $2; exit }' "$PROFILES_INI")

if [[ -z "$PROFILE_PATH" ]]; then
  echo "Could not determine default Firefox profile, skipping."
  exit 1
fi

CHROME_DIR="$PROFILES_DIR/$PROFILE_PATH/chrome"
mkdir -p "$CHROME_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ln -sf "$SCRIPT_DIR/userChrome.css" "$CHROME_DIR/userChrome.css"
ln -sf "$SCRIPT_DIR/user.js" "$PROFILES_DIR/$PROFILE_PATH/user.js"
ln -sf "$SCRIPT_DIR/tridactylrc" "$HOME/.config/tridactyl/tridactylrc"

echo "Linked userChrome.css -> $CHROME_DIR/userChrome.css"
echo "Linked user.js -> $PROFILES_DIR/$PROFILE_PATH/user.js"
echo "Linked tridactylrc -> $HOME/.config/tridactyl/tridactylrc"
