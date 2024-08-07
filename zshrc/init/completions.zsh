
gh_source Aloxaf/fzf-tab/fzf-tab.plugin.zsh

zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' prefix ''
zstyle ':fzf-tab:*' continuous-trigger 'tab'
zstyle ':fzf-tab:*' single-group color header
# zstyle ':fzf-tab:*' continuous-trigger 'right' # not needed because of `right:replace-query`

zstyle ':completion:*' fzf-search-display true
zstyle ':completion:*' insert-tab false
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # set list-colors to enable filename colorizing
# make comletion case insensitive
zstyle ':completion:*:git-checkout:*' sort false # disable sort when completing `git checkout`
zstyle ':completion:*:descriptions' format '[%d]' # set descriptions format to enable group support

zstyle ':fzf-tab:complete:*' fzf-min-height 30  


# zstyle ':fzf-tab:sources' config-directory "$DOTFILES/zshrc/completion-preview-specs"
gh_source yarden-zamir/fzf-tab-source/fzf-tab-source.plugin.zsh



# ZSH_AUTOSUGGEST_STRATEGY=(AI history completion)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
gh_source zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh

# ngrok
# To install shell completions, add this to your profile:
if command -v ngrok &>/dev/null; then
    eval "$(ngrok completion)"
fi