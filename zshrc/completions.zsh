
gh_source Aloxaf/fzf-tab/fzf-tab.plugin.zsh

zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' prefix ''
# zstyle ':fzf-tab:*' continuous-trigger 'right' # not needed because of `right:replace-query`

zstyle ':completion:*' fzf-search-display true
zstyle ':completion:*' insert-tab false
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # set list-colors to enable filename colorizing

zstyle ':completion:*:git-checkout:*' sort false # disable sort when completing `git checkout`
zstyle ':completion:*:descriptions' format '[%d]' # set descriptions format to enable group support

zstyle ':fzf-tab:complete:*' fzf-min-height 20

zstyle ':fzf-tab:sources' config-directory "$DOTFILES/zshrc/completion-preview-specs"
gh_source Freed-Wu/fzf-tab-source/fzf-tab-source.plugin.zsh


ZSH_AUTOSUGGEST_STRATEGY=(history completion)
gh_source zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh