#! /bin/bash
# for global bindings see: $DOTFILES/.skhdrc
gh_source --loaded zsh-users/zsh-history-substring-search && {
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
}

# gh_source --loaded andreacasarin/zsh-ask-opencode && {
    bindkey '^o' ask_atuin_ai
# }

if (( ${+widgets[navigate]} )); then
    bindkey '^@' navigate #ctrl+space / ctrl+@
    bindkey '^l' navigate #ctrl+space / ctrl+@
fi
if (( ${+widgets[navgator-create]} )); then
    bindkey '^n' navgator-create #ctrl+n: create new project
fi
if (( ${+widgets[ai-sessions]} )); then
    bindkey '^s' ai-sessions #ctrl+s: AI session picker
fi
if (( ${+widgets[jq-complete]} )); then
    # jq-zsh-plugin (see $DOTFILES/zshenv/init/jq.zsh) binds alt+j itself.
    # ^] is the only ctrl chord left unbound: every ctrl+letter is taken, ^C is
    # eaten by the tty, ^X is a prefix, ^_ is undo, ^\ risks SIGQUIT.
    bindkey '^]' jq-complete #ctrl+]: build a jq filter for the piped command
    bindkey -r '^[j'
fi

type -p fzf &>/dev/null && {
    # bindkey '^a' browse_apps
    bindkey '^z' fzf-cd-widget
    bindkey '^f' fzf-file-widget
    type - p rg &>/dev/null &&
        bindkey '^[ ' ripgrep_search #alt+space
}
bindkey '^b' open-harness
# Use fzf with syntax highlighted history
# bindkey '^R' fzf-history-syntax-highlighted-widget

# function nuc() {
#     python nuc.py search "" | fzf \
#         --disabled \
#         --preview 'bat -pl md --color always ~/Github/me/{} 2> /dev/null || echo ...' \
#         --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
#         --bind "change:reload:direnv exec ~/Desktop python ~/Desktop/nuc.py search {q} --min-score 0.2" \
#         --bind "ctrl-r:unbind(change,ctrl-f)+change-prompt(2. fzf> )+enable-search+rebind(ctrl-r)+transform-query(echo {q} > /tmp/rg-fzf-r; cat /tmp/rg-fzf-f)" | xargs -I{} nvim ~/Github/me/{}
# }

# zle -N nuc
# bindkey '^n' nuc


# bindkey '^b' git-branch
# bindkey '^h' git-history
