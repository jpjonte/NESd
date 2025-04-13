#!/usr/bin/env bash

name=$1

color=$(magick "$name".svg -colorspace srgb -format "%[hex:p{512,512}]" info:)

magick -background none +antialias "$name".svg "$name".png
magick -background "#$color" +antialias "$name".svg "$name-adaptive".png
