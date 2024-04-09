export FPATH=$HOME/.zfunc/:$FPATH
export FPATH=/usr/share/zsh/5.8.1/functions:$FPATH
export FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
export FPATH="$DOTFILES/completions:$FPATH"
gh_source yarden-zamir/zsh-act-completion \
    "export FPATH=$FPATH:{}/zsh"
gh_source perlpunk/shell-completions \
    "export FPATH=$FPATH:{}/zsh"

autoload -Uz compinit

compinit

for file in "$DOTFILES"/completions/*.zsh; do
    source "$file"
done