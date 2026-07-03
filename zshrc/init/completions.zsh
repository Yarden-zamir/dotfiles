
gh_source Aloxaf/fzf-tab/fzf-tab.plugin.zsh
typeset -gU fpath
[[ -d ${FZF_TAB_HOME:-}/lib ]] && fpath=($fpath "$FZF_TAB_HOME/lib")
# zstyle ':fzf-tab:*' use-zcompui yes
# zstyle ':fzf-tab:*' zcompui-command /Users/kcw/Github/fzf-tab/target/release/zcompui

zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' prefix ''
zstyle ':fzf-tab:*' continuous-trigger 'tab'
zstyle ':fzf-tab:*' single-group color header
zstyle ':fzf-tab:*' auto-accept-single false

zstyle ':completion:*' fzf-search-display true
zstyle ':completion:*' insert-tab false
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS} # set list-colors to enable filename colorizing
# make comletion case insensitive
zstyle ':completion:*:git-checkout:*' sort false # disable sort when completing `git checkout`
zstyle ':completion:*:descriptions' format '[%d]' # set descriptions format to enable group support
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:complete:*' fzf-min-height 30  
zstyle ':completion:*' prefix-needed false
zstyle ':completion:*' menu select

# zstyle ':fzf-tab:sources' config-directory "$DOTFILES/zshrc/completion-preview-specs"
gh_source yarden-zamir/fzf-tab-source/fzf-tab-source.plugin.zsh



# ZSH_AUTOSUGGEST_STRATEGY=(AI history completion)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_STRATEGY=(history)
gh_source zsh-users/zsh-autosuggestions/zsh-autosuggestions.zsh

#helllo
