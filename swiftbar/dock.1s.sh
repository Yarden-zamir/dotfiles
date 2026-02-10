#!/bin/zsh

JSON_PATH="$HOME/.cache/dock_apps.json"

# --- Main Logic: Get Dock apps and update a cache file ---

# Get the current list of apps from the Dock as a raw string
dock_apps_raw=$(
  osascript -e 'tell application "System Events" to get the name of every UI element of list 1 of process "Dock"'
)

# Use zsh parameter expansion to split the string by ", " into an array
apps_array=("${(@s/, /)dock_apps_raw}")

# Build a new JSON array from the app list
json_elements=()
for app in "${apps_array[@]}"; do
  # Escape each app name for JSON
  app_escaped=$(
    printf '%s' "$app" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
  )
  json_elements+=("$app_escaped")
done

# Join the escaped elements with a comma and wrap in brackets
# ${(j/,/)json_elements} is the zsh way to join an array with a delimiter
new_json="[${(j/,/)json_elements}]"

# If the cache file doesn't exist or the dock content has changed, update it
if [[ ! -f "$JSON_PATH" ]] || [[ "$new_json" != "$(<"$JSON_PATH")" ]]; then
  printf '%s\n' "$new_json" >"$JSON_PATH"
fi

# --- SwiftBar Output: Display status in the menu bar ---

echo "Dock ✅"
echo "---"
# Read the content from the cache file to display it
if [ -f "$JSON_PATH" ]; then
  # Use python to parse the JSON and print a clean, comma-separated list
  pretty_list=$(
    <"$JSON_PATH" | python3 -c 'import json, sys; print(", ".join(json.load(sys.stdin)))'
  )
  echo "Apps: $pretty_list"
else
  echo "Initializing..."
fi
echo "---"
echo "Last check: $(date)"
