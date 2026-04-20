#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Run Dock App
# @raycast.mode silent
# @raycast.packageName System
#
# Optional parameters:
# @raycast.icon 🧰
#
# Documentation:
# @raycast.description Launch Dock app by index (real-time)
# @raycast.author Yarden
# @raycast.authorURL https://github.com/yarden-zamir
# @raycast.argument1 { "type": "text", "placeholder": "0", "percentEncoded": true}

JSON_PATH="$HOME/.cache/dock_apps.json"
user_choice=$1

if [[ ! -f "$JSON_PATH" ]]; then
    echo "Dock app list not available"
    exit 1
fi

apps_count=$(jq 'length' "$JSON_PATH")
if [[ "$user_choice" -ge 0 && "$user_choice" -lt "$apps_count" ]]; then
    app_name=$(jq -r ".[$user_choice]" "$JSON_PATH")
    echo "$app_name"
    open -a "$app_name"
else
    echo "Invalid index: $user_choice. Valid range: 0 to $((apps_count - 1))."
fi
