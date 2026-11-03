#!/usr/bin/env bash
# Rebuild this desktop setup on a fresh Mac. Safe to re-run: every step checks
# before it acts, and anything already in the way is moved to <name>.bak.<date>
# rather than overwritten.
#
#   ./install.sh            everything
#   ./install.sh --dry-run  print what would change, touch nothing
#   ./install.sh --no-brew  skip `brew bundle` (configs only)
#
# Configs are SYMLINKED, not copied — edit them in this repo and the change is
# live (reload the app; see README for each one's reload command).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0
BREW=1
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --no-brew) BREW=0 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

STAMP="$(date +%Y%m%d-%H%M%S)"
say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
run()  { if [ "$DRY" = 1 ]; then note "[dry-run] $*"; else "$@"; fi; }

# link <repo-relative source> <absolute target>
link() {
  local src="$REPO/$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    note "ok      $dst"
    return
  fi
  run mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    note "backup  $dst -> $dst.bak.$STAMP"
    run mv "$dst" "$dst.bak.$STAMP"
  fi
  note "link    $dst -> $src"
  run ln -s "$src" "$dst"
}

# copy <repo-relative source> <absolute target> — for files an app won't read
# through a symlink (Firefox's install dir and profile).
copy() {
  local src="$REPO/$1" dst="$2"
  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    note "ok      $dst"
    return
  fi
  run mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ]; then
    note "backup  $dst -> $dst.bak.$STAMP"
    run cp "$dst" "$dst.bak.$STAMP"
  fi
  note "copy    $dst"
  run cp "$src" "$dst"
}

# ---------------------------------------------------------------------------
say "Homebrew packages"
if [ "$BREW" = 1 ]; then
  if ! command -v brew >/dev/null 2>&1; then
    if [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      note "Homebrew not found. Install it first: https://brew.sh"
      exit 1
    fi
  fi
  if [ "$DRY" = 1 ]; then
    brew bundle check --file="$REPO/Brewfile" --verbose || true
  else
    brew bundle --file="$REPO/Brewfile"
  fi
else
  note "skipped (--no-brew)"
fi

# ---------------------------------------------------------------------------
say "Config symlinks"
NU_DIR="$HOME/Library/Application Support/nushell"
link aerospace/aerospace.toml "$HOME/.aerospace.toml"
link sketchybar               "$HOME/.config/sketchybar"
link borders                  "$HOME/.config/borders"
link ghostty                  "$HOME/.config/ghostty"
link starship/starship.toml   "$HOME/.config/starship.toml"
link nvim                     "$HOME/.config/nvim"
link nushell/config.nu        "$NU_DIR/config.nu"
link nushell/env.nu           "$NU_DIR/env.nu"
link firefox/tridactylrc      "$HOME/.config/tridactyl/tridactylrc"
run mkdir -p "$HOME/.vim/undodir"   # nvim undofile dir (init.lua)

# ---------------------------------------------------------------------------
say "Background services (SketchyBar, JankyBorders)"
for svc in sketchybar borders; do
  if ! command -v "$svc" >/dev/null 2>&1; then
    note "$svc not installed — skipping"
  elif pgrep -xq "$svc"; then
    note "restart $svc"
    run brew services restart "$svc"
  else
    note "start   $svc"
    run brew services start "$svc"
  fi
done

if [ -d /Applications/AeroSpace.app ]; then
  if pgrep -xq AeroSpace; then
    note "reload  AeroSpace config"
    run aerospace reload-config || true
  else
    note "launch  AeroSpace (grant Accessibility when macOS asks)"
    run open -a AeroSpace
  fi
fi

# ---------------------------------------------------------------------------
say "Firefox"
FF_APP=""
for d in "$HOME/Applications/Firefox.app" /Applications/Firefox.app; do
  [ -d "$d" ] && { FF_APP="$d"; break; }
done

if [ -z "$FF_APP" ]; then
  note "Firefox not installed — skipping"
else
  RES="$FF_APP/Contents/Resources"
  # Autoconfig: locks the home/new-tab page, focuses content not the URL bar,
  # Cmd+E toggles the hidden nav bar. Needs sudo if Firefox is in /Applications
  # and not owned by you.
  if [ -w "$RES" ]; then SUDO=(); else SUDO=(sudo); note "$RES not writable — using sudo"; fi
  if ! cmp -s "$REPO/firefox/autoconfig/local-settings.js" "$RES/defaults/pref/local-settings.js" 2>/dev/null \
     || ! cmp -s "$REPO/firefox/autoconfig/mozilla.cfg" "$RES/mozilla.cfg" 2>/dev/null; then
    note "copy    autoconfig -> $RES"
    run ${SUDO[@]+"${SUDO[@]}"} mkdir -p "$RES/defaults/pref"
    run ${SUDO[@]+"${SUDO[@]}"} cp "$REPO/firefox/autoconfig/local-settings.js" "$RES/defaults/pref/local-settings.js"
    run ${SUDO[@]+"${SUDO[@]}"} cp "$REPO/firefox/autoconfig/mozilla.cfg" "$RES/mozilla.cfg"
  else
    note "ok      autoconfig"
  fi
  note "(Firefox updates replace the app bundle — re-run install.sh after one if the home page or Cmd+E stop working.)"

  # Profile files go into the profile Firefox actually launches: an
  # [Install...] section's Default in profiles.ini (one per Firefox install, so
  # take the most recently used), falling back to *.default-release.
  FF_SUPPORT="$HOME/Library/Application Support/Firefox"
  PROFILE=""
  if [ -f "$FF_SUPPORT/profiles.ini" ]; then
    newest=0
    while IFS= read -r rel; do
      [ -f "$FF_SUPPORT/$rel/prefs.js" ] || continue
      t=$(stat -f %m "$FF_SUPPORT/$rel/prefs.js")
      if [ "$t" -gt "$newest" ]; then newest=$t; PROFILE="$FF_SUPPORT/$rel"; fi
    done < <(awk -F= '/^\[Install/ {i=1; next} /^\[/ {i=0} i && $1=="Default" {print $2}' "$FF_SUPPORT/profiles.ini")
  fi
  if [ -z "$PROFILE" ]; then
    PROFILE=$(find "$FF_SUPPORT/Profiles" -maxdepth 1 -name '*.default-release' -print -quit 2>/dev/null || true)
  fi
  if [ -z "$PROFILE" ]; then
    note "no Firefox profile yet — launch Firefox once, quit it, then re-run install.sh"
  else
    note "profile $PROFILE"
    copy firefox/user.js        "$PROFILE/user.js"
    copy firefox/userChrome.css "$PROFILE/chrome/userChrome.css"
    copy firefox/userContent.css "$PROFILE/chrome/userContent.css"
  fi

  # Home page server: http://localhost:8347 (Tridactyl can't run on file://).
  PLIST="$HOME/Library/LaunchAgents/local.firefox-home-server.plist"
  RENDERED="$(sed "s#@FIREFOX_HOME_DIR@#$REPO/firefox/home#g" "$REPO/firefox/firefox-home-server.plist")"
  if [ -f "$PLIST" ] && [ "$(cat "$PLIST")" = "$RENDERED" ] \
     && launchctl print "gui/$(id -u)/local.firefox-home-server" >/dev/null 2>&1; then
    note "ok      home-page server (http://localhost:8347)"
  else
    note "install home-page server LaunchAgent"
    if [ "$DRY" = 0 ]; then
      mkdir -p "$(dirname "$PLIST")"
      printf '%s\n' "$RENDERED" > "$PLIST"
      launchctl bootout "gui/$(id -u)/local.firefox-home-server" 2>/dev/null || true
      launchctl bootstrap "gui/$(id -u)" "$PLIST"
    else
      note "[dry-run] write $PLIST and launchctl bootstrap it"
    fi
  fi

  # Tridactyl native messenger: lets Tridactyl read ~/.config/tridactyl/tridactylrc.
  if [ -f "$HOME/Library/Application Support/Mozilla/NativeMessagingHosts/tridactyl.json" ]; then
    note "ok      Tridactyl native messenger"
  else
    note "install Tridactyl native messenger"
    if [ "$DRY" = 0 ]; then
      tmp="$(mktemp -d)"
      curl -fsSL https://raw.githubusercontent.com/tridactyl/tridactyl/master/native/install.sh -o "$tmp/install.sh"
      sh "$tmp/install.sh" master
      rm -rf "$tmp"
    fi
  fi

  # The extension itself (the "No New Tab" build, so it doesn't fight the
  # autoconfig new-tab page). Opening the .xpi in Firefox shows the install prompt.
  if [ -n "$PROFILE" ] && grep -q 'tridactyl.vim.betas.nonewtab@cmcaine.co.uk' "$PROFILE/extensions.json" 2>/dev/null; then
    note "ok      Tridactyl extension"
  else
    note "Tridactyl extension missing — opening its installer in Firefox (press Cmd+E first so the prompt can show)"
    run open -a "$FF_APP" "https://tridactyl.cmcaine.co.uk/betas/nonewtab/tridactyl_no_new_tab_beta-latest.xpi"
  fi
fi

# ---------------------------------------------------------------------------
say "Done"
cat <<'EOF'
    One-time manual steps (macOS won't let a script do these):
      • System Settings → Privacy & Security → Accessibility: allow AeroSpace
      • System Settings → Control Center → "Automatically hide and show the
        menu bar" → Always   (SketchyBar replaces it)
      • Optional: ./macos/defaults.sh for the AeroSpace-friendly macOS tweaks
      • First `nvim` launch clones every plugin; then :CopilotSignIn
EOF
