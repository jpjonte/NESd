#!/usr/bin/env bash
# Generate the Play Store "What's new" text from CHANGELOG.md.
#
#   play_release_notes.sh [changelog] [budget]

set -euo pipefail

changelog=${1:-CHANGELOG.md}
budget=${2:-500}
hint="See the full changelog on GitHub."

if [ ! -f "$changelog" ]; then
  echo "play_release_notes: no such file: $changelog" >&2
  exit 1
fi

if [[ ! $budget =~ ^[1-9][0-9]*$ ]]; then
  echo "play_release_notes: budget must be a positive integer, got '$budget'" >&2
  exit 1
fi

byte_len() { printf '%s' "$1" | wc -c | tr -d ' '; }

entries=()

while IFS= read -r entry; do
  entries+=("$entry")
done < <(
  awk '
    /^## \[[0-9]+\.[0-9]+\.[0-9]+\]/ {
      if (found)
        exit

      found = 1
      next
    }
    found
  ' "$changelog" |
    sed -E \
      -e 's/\[([^]]*)\]\([^)]*\)/\1/g' \
      -e 's/\*\*([^*]*)\*\*/\1/g' \
      -e 's/`([^`]*)`/\1/g' |
    awk '
      { sub(/[[:space:]]+$/, "") }
      /^### /            { printf "h\t%s\n", substr($0, 5); next }
      /^- /              { printf "b\t%s\n", $0; next }
      /^[[:space:]]+- /  { sub(/^[[:space:]]+/, "  "); printf "c\t%s\n", $0 }
    '
)

if [ ${#entries[@]} -eq 0 ]; then
  echo "play_release_notes: no release section found in $changelog" >&2
  exit 1
fi

blocks=()
kinds=()
current=""
current_kind=""

flush_block() {
  if [ -n "$current_kind" ]; then
    blocks+=("$current")
    kinds+=("$current_kind")
  fi

  current=""
  current_kind=""
}

for entry in "${entries[@]}"; do
  kind=${entry%%$'\t'*}
  text=${entry#*$'\t'}

  case "$kind" in
    h|b)
      flush_block
      current="$text"
      current_kind="$kind"
      ;;
    c)
      if [ "$current_kind" = b ]; then
        current+=$'\n'"$text"
      fi
      ;;
  esac
done

flush_block

pruned_blocks=()
pruned_kinds=()

for i in "${!blocks[@]}"; do
  if [ "${kinds[$i]}" = h ]; then
    next=$((i + 1))

    if [ "$next" -ge "${#blocks[@]}" ] || [ "${kinds[$next]}" = h ]; then
      continue
    fi
  fi

  pruned_blocks+=("${blocks[$i]}")
  pruned_kinds+=("${kinds[$i]}")
done

if [ ${#pruned_blocks[@]} -eq 0 ]; then
  echo "play_release_notes: the newest section has no bullets" >&2
  exit 1
fi

out=""
started=0

add_block() {
  local kind=$1 text=$2

  if [ "$kind" = h ] && [ "$started" -eq 1 ]; then
    out+=$'\n'
  fi

  out+="$text"$'\n'
  started=1
}

for i in "${!pruned_blocks[@]}"; do
  add_block "${pruned_kinds[$i]}" "${pruned_blocks[$i]}"
done

if [ "$(byte_len "$out")" -le "$budget" ]; then
  printf '%s' "$out"
  exit 0
fi

reserve=$(byte_len $'\n'"$hint"$'\n')
limit=$((budget - reserve))

out=""
started=0
pending=""
has_pending=0

for i in "${!pruned_blocks[@]}"; do
  kind=${pruned_kinds[$i]}
  text=${pruned_blocks[$i]}

  if [ "$kind" = h ]; then
    pending="$text"
    has_pending=1
    continue
  fi

  saved_out="$out"
  saved_started="$started"

  if [ "$has_pending" -eq 1 ]; then
    add_block h "$pending"
  fi

  add_block b "$text"

  if [ "$(byte_len "$out")" -gt "$limit" ]; then
    out="$saved_out"
    started="$saved_started"
    break
  fi

  pending=""
  has_pending=0
done

if [ -z "$out" ]; then
  echo "play_release_notes: nothing fits in $budget bytes" >&2
  exit 1
fi

out+=$'\n'"$hint"$'\n'

printf '%s' "$out"
