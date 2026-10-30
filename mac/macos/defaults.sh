#!/usr/bin/env bash
# Optional macOS settings that make AeroSpace + SketchyBar behave. Not run by
# install.sh — these change system-wide behaviour, so run this by hand once.
# Every line is a `defaults write`; undo any of them with `defaults delete
# <domain> <key>`.

set -euo pipefail

# Mission Control: group windows by app. AeroSpace parks windows of hidden
# workspaces off-screen; without this, Mission Control shows them as tiny
# slivers. (Recommended in AeroSpace's guide.)
defaults write com.apple.dock expose-group-apps -bool true

# Turn OFF "Displays have separate Spaces". AeroSpace manages its own
# workspaces per monitor; macOS Spaces per display fight it. Needs a logout.
defaults write com.apple.spaces spans-displays -bool true

# Don't reorder macOS Spaces by most-recent use.
defaults write com.apple.dock mru-spaces -bool false

# Hide the native menu bar — SketchyBar draws its own bar in that strip.
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# Ctrl+Cmd+drag anywhere in a window to move it (handy for floating windows).
defaults write -g NSWindowShouldDragOnGesture -bool true

killall Dock SystemUIServer 2>/dev/null || true
echo "Done. Log out and back in for the Spaces change to take effect."
