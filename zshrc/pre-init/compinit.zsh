export FPATH=$HOME/.zfunc/:$FPATH
export FPATH=/usr/share/zsh/5.8.1/functions:$FPATH
export FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

gh_source perlpunk/shell-completions \
    "export FPATH=$FPATH:{}/zsh"

autoload -Uz compinit
compinit
