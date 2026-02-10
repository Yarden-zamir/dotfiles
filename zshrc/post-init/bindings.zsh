#! /bin/bash
# for global bindings see: $DOTFILES/.skhdrc
gh_source --require zsh-users/zsh-history-substring-search && {
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
}

type -p fzf &>/dev/null && {
    # bindkey '^a' browse_apps
    bindkey '^@' navigate #ctrl+space / ctrl+@
    bindkey '^l' navigate #ctrl+space / ctrl+@
    bindkey '^z' fzf-cd-widget
    bindkey '^f' fzf-file-widget
    type - p rg &>/dev/null &&
        bindkey '^[ ' ripgrep_search #alt+space
}
# ctrl + enter to open in vscode
bindkey '^o' open-with
# bindkey '^[b' open-with
bindkey '^k' open-with-code
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

