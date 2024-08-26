#!/usr/bin/env sh

lcov -r coverage/lcov.info \
  --ignore-errors unused \
  'lib/*/*.freezed.dart' \
  'lib/*/*.g.dart' \
  -o coverage/lcov_cleaned.info

output=$(lcov --summary coverage/lcov_cleaned.info)

lines_coverage=$(echo "$output" | grep "lines......." | awk '{print $2}' | xargs printf "%.0f")

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
