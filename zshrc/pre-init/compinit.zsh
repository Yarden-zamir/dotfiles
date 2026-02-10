if [[ -n ${ZSH_PROFILE-} ]]; then
  zmodload zsh/datetime 2>/dev/null
  _zsh_profile_time() {
    local label=$1
    shift
    local -F start end elapsed

    if [[ -n ${EPOCHREALTIME-} ]]; then
      start=$EPOCHREALTIME
      "$@"
      end=$EPOCHREALTIME
      elapsed=$(( end - start ))
    else
      local start_s=$SECONDS
      "$@"
      local end_s=$SECONDS
      elapsed=$(( end_s - start_s ))
    fi

    printf 'zsh-profile: %.6fs compinit %s\n' "$elapsed" "$label" >&2
  }
else
  _zsh_profile_time() {
    local _label=$1
    shift
    (( $# )) || return 0
    "$@"
  }
fi

_dotfiles_brew_fpath() {
  local brew_prefix brew_path

  brew_prefix=${HOMEBREW_PREFIX-}
  if [[ -n $brew_prefix ]] && [[ -d $brew_prefix/share/zsh/site-functions ]]; then
    export FPATH="$brew_prefix/share/zsh/site-functions:${FPATH}"
    return 0
  fi

  brew_path=${commands[brew]:-}
  [[ -n $brew_path ]] || return 0
  brew_prefix=${brew_path%/bin/brew}
  [[ -d $brew_prefix/share/zsh/site-functions ]] || return 0
  export FPATH="$brew_prefix/share/zsh/site-functions:${FPATH}"
}

_dotfiles_source_completions() {
  local file

  for file in "$DOTFILES"/completions/*.zsh(N); do
    source "$file"
  done
}

export FPATH=$HOME/.zfunc/:$FPATH
export FPATH=/usr/share/zsh/5.8.1/functions:$FPATH
_zsh_profile_time "brew prefix" _dotfiles_brew_fpath
export FPATH="$DOTFILES/completions:$FPATH"
_zsh_profile_time "gh_source perlpunk/shell-completions" gh_source perlpunk/shell-completions \
  "export FPATH=$FPATH:{}/zsh"
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

autoload -Uz compinit
_zsh_profile_time "compinit -u" compinit -u
_zsh_profile_time "source $DOTFILES/completions" _dotfiles_source_completions
