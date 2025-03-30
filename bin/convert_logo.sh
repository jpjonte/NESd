#!/usr/bin/env bash

name=$1

magick -background none +antialias "$name".svg "$name".png
