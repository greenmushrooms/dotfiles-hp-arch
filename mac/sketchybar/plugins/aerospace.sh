#!/usr/bin/env bash
# Batched workspace indicator, driven by ONE observer item (see sketchybarrc).
#
# The naive pattern (one script per item, subscribed individually) spawns 9
# bash processes on every workspace switch, and each non-focused one makes its
# own `aerospace list-windows` IPC call. That process/IPC storm is what made
# the highlight lag.
#
# Here a single invocation draws in two passes: pass 1 flushes the focused
# highlight immediately (no IPC needed for the focused/not split), then pass 2
# makes the single occupancy query and refines the remaining items into bright
# (occupied) vs dim (empty). The pixel the user is watching lands first; the
# dimming trails it imperceptibly.

# Palette (scripts don't inherit sketchybarrc's variables).
ON_ACCENT=0xff1e1e2e   # text on the focused (accent) pill
FG=0xffcad3f5
DIM=0xff6c7086

# --- Fast path: paint the highlight before anything else --------------------
# AeroSpace hands us the new workspace in FOCUSED_WORKSPACE, so the highlight
# can land with ONE sketchybar call: no lock, no aerospace query. Without this,
# the switch waited behind the ~90ms focused query and, worse, behind whatever
# draw held the lock (a switch also fires front_app_switched, whose full draw
# often grabbed the lock first) — ~0.4s of visible lag. If bursts make this
# paint stale, the locked loop below re-queries and corrects it.
#
# LAST remembers the previously focused workspace so only its (dark-on-accent)
# icon gets recolored; touching the others here would flash dimmed ones bright.
LAST="${TMPDIR:-/tmp}/sketchybar_aerospace.last"
# OCCUPIED_FILE caches pass 2's occupancy list so the fast path can pick bright
# vs dim for the workspace we left without an aerospace query.
OCCUPIED_FILE="${TMPDIR:-/tmp}/sketchybar_aerospace.occupied"
if [ "$SENDER" = "aerospace_workspace_change" ] && [ -n "$FOCUSED_WORKSPACE" ]; then
  prev=$(cat "$LAST" 2>/dev/null)
  echo "$FOCUSED_WORKSPACE" > "$LAST" 2>/dev/null
  ARGS=()
  for sid in 1 2 3 4 5 6 7 8 9; do
    if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
      ARGS+=(--set "space.$sid" background.drawing=on  icon.color=$ON_ACCENT)
    else
      ARGS+=(--set "space.$sid" background.drawing=off)
    fi
  done
  sketchybar "${ARGS[@]}"

  # Then recolor the workspace we left (its number was dark-on-accent).
  if [ -n "$prev" ] && [ "$prev" != "$FOCUSED_WORKSPACE" ]; then
    occupied=$(cat "$OCCUPIED_FILE" 2>/dev/null)
    if [[ "$occupied" == *" $prev "* ]]; then c=$FG; else c=$DIM; fi
    sketchybar --set "space.$prev" icon.color=$c
  fi
fi

# front_app_switched fires at the same moment as a workspace switch; it only
# needs to refresh occupancy (windows opened/closed), so let the highlight
# paint uncontested first.
[ "$SENDER" = "front_app_switched" ] && sleep 0.25

# --- Coalescing lock ---------------------------------------------------------
# During a rapid burst of switches, only ONE draw runs at a time. But we must
# never DROP the final switch: if events arrive mid-draw we set a "dirty" flag
# and the running instance loops again, so the bar always converges on the real
# current workspace. (The old design exited on a held lock, which could leave
# the last switch of a burst undrawn — hence the out-of-sync symptom.)
#
# The dirty flag deliberately lives OUTSIDE the lock dir. Inside it, every
# writer raced the holder's `rm -rf "$LOCK"` EXIT trap and lost, spewing "No
# such file or directory" into sketchybar.err.log on nearly every switch (that
# log had grown to 149MB). TMPDIR always exists, so the write can't fail. A
# flag left behind by a killed instance is harmless: the next draw clears it
# before painting, costing at most one redundant loop pass.
LOCK="${TMPDIR:-/tmp}/sketchybar_aerospace.lock"
DIRTY="${TMPDIR:-/tmp}/sketchybar_aerospace.dirty"
OWNER="$LOCK/pid"

if ! mkdir "$LOCK" 2>/dev/null; then
  # Lock is held. Either a draw is genuinely in flight, or a previous draw was
  # killed (e.g. SIGKILL on a sketchybar restart) before its EXIT trap could
  # clean up — leaving an orphaned lock that would otherwise freeze the bar,
  # since every future event would just set dirty and exit here forever.
  owner_pid=$(cat "$OWNER" 2>/dev/null)
  if [ -n "$owner_pid" ] && kill -0 "$owner_pid" 2>/dev/null; then
    # Real draw in flight — flag that state changed and let it repaint.
    # 2>/dev/null must precede the target: bash applies redirections left to
    # right, so trailing suppression would come too late to hide an open error.
    : 2>/dev/null > "$DIRTY"
    exit 0
  fi
  # Stale lock: owner is gone (or unknown). Reclaim it and continue to draw.
  rm -rf "$LOCK" 2>/dev/null
  mkdir "$LOCK" 2>/dev/null || { : 2>/dev/null > "$DIRTY"; exit 0; }
fi
echo "$$" > "$OWNER" 2>/dev/null
trap 'rm -rf "$LOCK" 2>/dev/null' EXIT

while :; do
  rm -f "$DIRTY" 2>/dev/null   # clear before drawing; any switch after this
                               # re-creates it and triggers another loop.

  # Query the focused workspace fresh each pass. We deliberately do NOT trust
  # the trigger's FOCUSED_WORKSPACE env here: during a burst it reflects the
  # switch that spawned us, which may already be stale by the time we draw.
  FOCUSED=$(aerospace list-workspaces --focused 2>/dev/null)
  echo "$FOCUSED" > "$LAST" 2>/dev/null

  # --- Pass 1: draw the focused highlight first. -----------------------------
  # Unfocused icon colors are left alone here: setting them bright and dimming
  # the empty ones in pass 2 made empty workspaces flash on every draw.
  ARGS=()
  for sid in 1 2 3 4 5 6 7 8 9; do
    if [ "$sid" = "$FOCUSED" ]; then
      ARGS+=(--set "space.$sid" drawing=on background.drawing=on  icon.color=$ON_ACCENT)
    else
      ARGS+=(--set "space.$sid" drawing=on background.drawing=off)
    fi
  done
  sketchybar "${ARGS[@]}"

  # --- Pass 2: dim empty workspaces. ----------------------------------------
  # All occupied (non-empty) workspaces in one call. Space-pad both sides so we
  # can match with a simple substring test without partial-number hits.
  OCCUPIED=" $(aerospace list-workspaces --monitor all --empty no --format '%{workspace}' 2>/dev/null | tr '\n' ' ') "
  echo "$OCCUPIED" > "$OCCUPIED_FILE" 2>/dev/null

  ARGS=()
  for sid in 1 2 3 4 5 6 7 8 9; do
    [ "$sid" = "$FOCUSED" ] && continue
    # Final color for every unfocused workspace, set exactly once per draw.
    if [[ "$OCCUPIED" == *" $sid "* ]]; then c=$FG; else c=$DIM; fi
    ARGS+=(--set "space.$sid" icon.color=$c)
  done
  sketchybar "${ARGS[@]}"

  # If a switch landed while we were drawing, repaint; otherwise we're current.
  [ -e "$DIRTY" ] || break
done
