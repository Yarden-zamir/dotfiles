#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Run Dock App 7
# @raycast.mode silent
# @raycast.packageName System
#
# Optional parameters:
# @raycast.icon 🧰
#
# Documentation:
# @raycast.description d
# @raycast.author Yarden
# @raycast.authorURL https://github.com/yarden-zamir
filename=$(basename "$0" | cut -d. -f1)  # Remove extension
./dock.sh "${filename: -1}"
