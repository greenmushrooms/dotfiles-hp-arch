#!/usr/bin/env bash
# Slack unread badge, read from the Dock badge via lsappinfo (no API token).
# Adapted from tifandotme/dotfiles. The count includes "Later" items — Slack
# offers no way to split them out; disable "Show badge for items in Later" in
# Slack's notification prefs if that's noise. A badge of "•" (unreads without
# mentions) shows as a dot.

ACCENT=0xff89b4fa
FG=0xffcad3f5
RED=0xfff38ba8

if ! pgrep -xq Slack; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

BADGE=$(lsappinfo info -only StatusLabel Slack 2>/dev/null | sed -n 's/.*"label"="\(.*\)".*/\1/p')
COUNT=${BADGE//[^0-9]/}

if [ -n "$COUNT" ] && [ "$COUNT" -gt 0 ]; then
  sketchybar --set "$NAME" drawing=on label="$COUNT" icon.color=$RED label.color=$RED
elif [ -n "$BADGE" ]; then
  sketchybar --set "$NAME" drawing=on label="•" icon.color=$ACCENT label.color=$FG
else
  sketchybar --set "$NAME" drawing=on label="0" icon.color=$ACCENT label.color=$FG
fi
