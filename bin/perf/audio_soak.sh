#!/usr/bin/env bash
# Unattended audio soak on the connected device.
# Usage: bin/perf/audio_soak.sh <rom-file> [seconds] [pcm] [label]
# Requires: dev-flavor profile build installed.
# NOTE: if the app crashes before printing NESD_SOAK, the logcat wait
# blocks forever — Ctrl-C and check `adb logcat -d | grep NESD`.
set -euo pipefail

ROM="$1"
DURATION="${2:-600}"   # NOT named SECONDS: that is a bash builtin
PCM="${3:-true}"
LABEL="${4:-$(basename "$ROM" .nes)}"
PKG=dev.jpj.nesd.dev
DIR="/sdcard/Android/data/$PKG/files/soak"
OUT="bin/perf/results/soak/$LABEL"

ROM_NAME=$(basename "$ROM")
case "$ROM_NAME" in
  *"'"*|*'"'*)
    echo "ERROR: ROM filename must not contain quotes: $ROM_NAME" >&2
    exit 64
    ;;
esac

FREQ=$(adb shell cat /sys/devices/system/cpu/cpufreq/policy6/scaling_cur_freq | tr -d '\r')
echo "big-cluster cur_freq: $FREQ (expect 1996800 when pinned)"

# PCM needs ~120 MB per 10 min; fall back to stats-only when tight.
# Unparseable df output disables PCM too (fail closed).
FREE_KB=$(adb shell df /sdcard | awk 'NR==2 {print $4}' | tr -d '\r')
if [ "$PCM" = "true" ]; then
  case "$FREE_KB" in
    ''|*[!0-9]*)
      echo "WARNING: could not parse device free space, disabling PCM dump"
      PCM=false
      ;;
    *)
      if [ "$FREE_KB" -lt 300000 ]; then
        echo "WARNING: <300 MB free on device, disabling PCM dump"
        PCM=false
      fi
      ;;
  esac
fi

adb shell mkdir -p "$DIR"
adb shell rm -f "$DIR/stats.log" "$DIR/audio.pcm"
adb push "$ROM" "$DIR/$ROM_NAME" >/dev/null
adb shell "echo '{\"rom\": \"$ROM_NAME\", \"seconds\": $DURATION, \"pcm\": $PCM}' > $DIR/soak.json"
adb shell input keyevent KEYCODE_WAKEUP
adb shell am force-stop "$PKG"
adb logcat -c
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1

echo "soaking for $DURATION seconds (plus load/teardown)..."
LINE=$(adb logcat -v raw -e "NESD_SOAK" -m 1 2>/dev/null | grep "NESD_SOAK" | head -1)
echo "$LINE"

if echo "$LINE" | grep -q "NESD_SOAK_FAILED"; then
  echo "soak failed on device; see adb logcat"
  exit 1
fi

mkdir -p "$OUT"
rm -f "$OUT/audio.pcm" "$OUT/audio.wav"
adb pull "$DIR/stats.log" "$OUT/" >/dev/null

REPORT_ARGS=(--stats "$OUT/stats.log" --out "$OUT")
if [ "$PCM" = "true" ]; then
  adb pull "$DIR/audio.pcm" "$OUT/" >/dev/null
  REPORT_ARGS+=(--pcm "$OUT/audio.pcm")
fi

fvm dart run bin/perf/soak_report.dart "${REPORT_ARGS[@]}" | tee "$OUT/report.txt"

# Append a summary record in the results ledger, tagged like bench runs.
EXHAUST=$(echo "$LINE" | sed -n 's/.*exhaust_total=\([0-9]*\).*/\1/p')
EPISODES=$(echo "$LINE" | sed -n 's/.*exhaust_episodes=\([0-9]*\).*/\1/p')
FILLMIN=$(echo "$LINE" | sed -n 's/.*fill_min=\([0-9]*\).*/\1/p')
echo "{\"label\": \"$LABEL\", \"kind\": \"audio-soak\", \"device\": \"$(adb shell getprop ro.product.model | tr -d '\r ')\", \"freq\": \"$FREQ\", \"rom\": \"$ROM_NAME\", \"seconds\": $DURATION, \"exhaust_total\": $EXHAUST, \"exhaust_episodes\": $EPISODES, \"fill_min\": $FILLMIN}" >> bin/perf/results/results.jsonl
