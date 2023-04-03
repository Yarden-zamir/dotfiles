export HISTSIZE=999999999
export SAVEHIST=$HISTSIZE
setopt EXTENDED_HISTORY
HISTFILE=~/.zsh_history
HISTIGNORE="cd:ls:clear:cd.:cd..:cd...:cd....:cd.....:cd......:cd~:cd-:cd/:open.:open-here:code.:code-here"

export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE="true"
export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND="true"
export HISTORY_SUBSTRING_SEARCH_PREFIXED=1
gh_source zsh-users/zsh-history-substring-search/zsh-history-substring-search.zsh