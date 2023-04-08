# for global bindings see: $DOTFILES/.skhdrc
gh_source --require zsh-users/zsh-history-substring-search && {
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
}

type -p fzf &>/dev/null && {
    bindkey '^a' browse_apps
    bindkey '^@' navigate #ctrl+space / ctrl+@
    bindkey '^o' fzf-file-or-folder-to-editor
    bindkey '^z' fzf-cd-widget
    bindkey '^f' fzf-file-widget
    type - p rg &>/dev/null && \
        bindkey '^[ ' ripgrep_search #alt+space
}
# Use fzf with syntax highlighted history
bindkey '^R' fzf-history-syntax-highlighted-widget