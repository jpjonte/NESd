#!/usr/bin/env bash

magick ci/1-build/macos/background@2x.png -resize 512x512 ci/1-build/macos/background.png

tiffutil -cathidpicheck ci/1-build/macos/background.png ci/1-build/macos/background@2x.png -out ci/1-build/macos/background.tiff
