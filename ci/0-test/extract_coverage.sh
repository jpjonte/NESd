#!/usr/bin/env sh

set -eu

ignore=unused

if lcov --version | grep -qE 'version 2'; then
  ignore=unused,empty
fi

lcov -r packages/nesd/coverage/lcov.info \
  --ignore-errors "$ignore" \
  'lib/*/*.freezed.dart' \
  'lib/*/*.g.dart' \
  -o packages/nesd/coverage/lcov_cleaned.info

output=$(lcov --summary packages/nesd/coverage/lcov_cleaned.info --ignore-errors "$ignore")

lines_coverage=$(echo "$output" | grep "lines......." | awk '{sub(/%/, "", $2); printf "%.0f", $2}')

case "$lines_coverage" in
  ''|*[!0-9]*)
    echo "could not read the line coverage from lcov --summary:" >&2
    echo "$output" >&2
    exit 1
    ;;
esac

if [ "$lines_coverage" -lt 50 ]; then
  color="red"
elif [ "$lines_coverage" -lt 70 ]; then
  color="orange"
elif [ "$lines_coverage" -lt 90 ]; then
  color="yellow"
else
  color="green"
fi

json=$(cat <<EOF
{
  "label": "coverage",
  "message": "$lines_coverage%",
  "color": "$color"
}
EOF
)

mkdir -p pages/coverage
echo "$json" > pages/coverage/main.json
