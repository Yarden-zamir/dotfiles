# Herdr pane helpers. The shell announces its own cwd: on every cd (and
# once at startup) a background one-shot syncs the workspace name and
# subtitle to the bare+container convention. Push, not poll - nothing
# runs at rest. Logic lives in .config/herdr/plugins/spaces/space-sync.
[[ -n ${HERDR_WORKSPACE_ID-} ]] || return 0

_herdr_space_sync() {
    "$DOTFILES/.config/herdr/plugins/spaces/space-sync" sync "$HERDR_WORKSPACE_ID" "$PWD" &>/dev/null &!
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _herdr_space_sync
_herdr_space_sync
