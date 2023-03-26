FPATH=$HOME/.zfunc/:$FPATH
FPATH=/usr/share/zsh/5.8.1/functions:$FPATH
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
autoload -Uz compinit
compinit
