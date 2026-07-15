#!/usr/bin/env bash
# Usage: bin/perf/device_bench.sh <rom-file> [frames] [label]
# Requires: dev-flavor profile build installed
set -euo pipefail

ROM="$1"
FRAMES="${2:-3000}"
LABEL="${3:-$(basename "$ROM")}"
PKG=dev.jpj.nesd.dev
DIR="/sdcard/Android/data/$PKG/files/bench"

FREQ=$(adb shell cat /sys/devices/system/cpu/cpufreq/policy6/scaling_cur_freq | tr -d '\r')
echo "big-cluster cur_freq: $FREQ (expect 1996800 when pinned)"

adb shell mkdir -p "$DIR"
adb push "$ROM" "$DIR/$(basename "$ROM")" >/dev/null
adb shell "echo '{\"rom\": \"$(basename "$ROM")\", \"frames\": $FRAMES}' > $DIR/bench.json"
adb shell am force-stop "$PKG"
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1

echo "waiting for NESD_BENCH line..."
LINE=$(adb logcat -v raw -e "NESD_BENCH " -m 1 2>/dev/null | grep "NESD_BENCH " | head -1)
echo "$LINE"

# Append to results.jsonl, tagged with the device.
MEDIAN=$(echo "$LINE" | sed -n 's/.*median_us=\([0-9]*\).*/\1/p')
P90=$(echo "$LINE" | sed -n 's/.*p90_us=\([0-9]*\).*/\1/p')
FPS=$(echo "$LINE" | sed -n 's/.*flatout_fps=\([0-9.]*\).*/\1/p')
mkdir -p bin/perf/results
echo "{\"label\": \"$LABEL\", \"device\": \"$(adb shell getprop ro.product.model | tr -d '\r ')\", \"freq\": \"$FREQ\", \"rom\": \"$(basename "$ROM")\", \"frames\": $FRAMES, \"median_us\": $MEDIAN, \"p90_us\": $P90, \"flatout_fps\": $FPS}" >> bin/perf/results/results.jsonl
