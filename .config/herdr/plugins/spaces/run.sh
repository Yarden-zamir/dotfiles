#!/bin/sh
# Run space-sync with uv. Usage: sh run.sh <space-sync subcommand>
#
# The herdr server gives plugin commands its own environment. A server that
# launchd or a GUI app started has a minimal PATH without uv, so add the
# usual install dirs here (Homebrew on macOS, ~/.local/bin on Linux).
# Remove this launcher when herdr resolves the login shell PATH for plugins.
PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH" exec uv run --script --quiet space-sync "$@"
