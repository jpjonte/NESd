#!/usr/bin/env sh

zip -r artifacts/"$ARTIFACT".windows-x64.zip artifacts/"$ARTIFACT".windows-x64

rm -rf artifacts/"$ARTIFACT".windows-x64
