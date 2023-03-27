export HISTSIZE=999999999
export SAVEHIST=$HISTSIZE
setopt EXTENDED_HISTORY
HISTFILE=~/.zsh_history
HISTIGNORE="cd:ls:clear:cd.:cd..:cd...:cd....:cd.....:cd......:cd~:cd-:cd/:open.:open-here:code.:code-here"


export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND=""
export HISTORY_SUBSTRING_SEARCH_PREFIXED=1
gh_source zsh-users/zsh-history-substring-search/zsh-history-substring-search.zsh
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down