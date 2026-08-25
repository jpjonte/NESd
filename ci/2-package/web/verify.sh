#!/usr/bin/env bash

set -eux

image="$1"

container=$(docker run -d -p 127.0.0.1:8080:80 "$image")
trap 'docker rm -f "$container"' EXIT

for _ in $(seq 1 40); do
  if curl -fsS -o /dev/null http://127.0.0.1:8080/; then
    break
  fi

  sleep 0.5
done

# verify correct mime type
curl -fsSI http://127.0.0.1:8080/main.dart.mjs \
  | grep -i '^content-type: application/javascript'

# verify correct cache header
curl -fsSI http://127.0.0.1:8080/index.html \
  | grep -i '^cache-control: no-store'
