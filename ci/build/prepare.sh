#!/usr/bin/env bash

set -eux

flutter pub get

find ~/.pub-cache/git -maxdepth 1 -type d -name 'mp-audio-stream*' -exec bash -c "cd {}; git submodule init && git submodule update" \;

dart pub global activate flutter_distributor
