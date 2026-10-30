#!/usr/bin/env bash
# Shows the name of the focused application in the center of the bar.

if [ "$SENDER" = "front_app_switched" ]; then
  sketchybar --set "$NAME" label="$INFO"
fi
