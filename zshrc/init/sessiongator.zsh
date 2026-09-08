[[ -o interactive ]] && stty -ixon 2>/dev/null

# Homebrew-managed; enable exactly one setup path.
# source "$(brew --prefix sessiongator)/share/sessiongator/sessiongator.zsh"

# Local checkout managed by gh-source.
gh_source Yarden-zamir/sessiongator/scripts/sessiongator.zsh \
    --skip-build-if-present target/release/sessiongator \
    --build cargo build --release

# Inside a herdr pane, Enter in the picker opens the session as a tab (or
# focuses its live pane) through the gators plugin, and live sessions are
# tagged. See .config/herdr/plugins/gators/sessions-open.
if [[ -n "$HERDR_PANE_ID" ]]; then
    export SESSIONGATOR_RESUME_HANDLER="$DOTFILES/.config/herdr/plugins/gators/sessions-open open"
    export SESSIONGATOR_LIVE_IDS_COMMAND="$DOTFILES/.config/herdr/plugins/gators/sessions-open live-ids"
fi
