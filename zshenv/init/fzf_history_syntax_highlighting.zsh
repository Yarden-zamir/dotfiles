function fzf-history-syntax-highlighted-widget() {
    history -n 0 | \
    sed 's/$/)/; s/^/$(/' | \
    bat -pl=zsh --color=always --paging never | \
    cut -c 45- | rev | cut -c 6- | rev | eval fzf $FZF_CTRL_R_OPTS
}

zle -N fzf-history-syntax-highlighted-widget fzf-history-syntax-highlighted-widget