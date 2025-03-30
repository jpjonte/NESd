#!/usr/bin/env bash

magick ci/build/macos/background@2x.png -resize 512x512 ci/build/macos/background.png

tiffutil -cathidpicheck ci/build/macos/background.png ci/build/macos/background@2x.png -out ci/build/macos/background.tiff
