#!/bin/sh
# Action: open the output popup. Runs on the server with no TTY, so it
# only asks herdr to open the plugin pane; output.sh does the display.
set -eu
exec "$HERDR_BIN_PATH" plugin pane open --plugin yarden.palette --entrypoint output
