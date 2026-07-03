if [[ -d /opt/homebrew ]]; then
  # Static replacement for `eval "$(brew shellenv)"`; avoids spawning brew on every login shell.
  export HOMEBREW_PREFIX=/opt/homebrew
  export HOMEBREW_CELLAR=/opt/homebrew/Cellar
  export HOMEBREW_REPOSITORY=/opt/homebrew
  export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

  typeset -gU path fpath
  path=(/opt/homebrew/bin /opt/homebrew/sbin $path)
  [[ -d /opt/homebrew/share/zsh/site-functions ]] && fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
fi
