#!/usr/bin/env bash
# CPU and RAM usage. Runs on the `cpu` item and updates `ram` too, so one
# process per tick covers both.
#
# CPU: summed per-process %CPU from ps, divided by core count. (`top -l 1` is
# the usual choice but its first sample is the average since boot, so it
# barely moves; `top -l 2` is accurate but blocks for a full second.)
# RAM: "Memory Used" as Activity Monitor defines it — app (anonymous) + wired
# + compressed pages — over physical memory.

FG=0xffcad3f5
ACCENT=0xff89b4fa
RED=0xfff38ba8

NCPU=$(sysctl -n hw.ncpu)
CPU=$(ps -A -o %cpu= | awk -v n="$NCPU" '{s+=$1} END {v=s/n; if (v>100) v=100; printf "%d", v}')

TOTAL=$(sysctl -n hw.memsize)
RAM=$(vm_stat | awk -v total="$TOTAL" '
  /page size of/                  { page=$8 }
  /Anonymous pages/               { anon=$3 }
  /Pages wired down/              { wired=$4 }
  /occupied by compressor/        { comp=$5 }
  /Pages purgeable/               { purge=$3 }
  END { printf "%d", (anon - purge + wired + comp) * page * 100 / total }')

color() { if [ "$1" -ge "$2" ]; then echo $RED; else echo "$3"; fi; }

sketchybar --set cpu label="${CPU}%" icon.color="$(color "$CPU" 80 $ACCENT)" label.color="$(color "$CPU" 80 $FG)" \
           --set ram label="${RAM}%" icon.color="$(color "$RAM" 85 $ACCENT)" label.color="$(color "$RAM" 85 $FG)"
