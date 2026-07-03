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
    fpath=("$brew_prefix/share/zsh/site-functions" $fpath)
    return 0
  fi

  brew_path=${commands[brew]:-}
  [[ -n $brew_path ]] || return 0
  brew_prefix=${brew_path%/bin/brew}
  [[ -d $brew_prefix/share/zsh/site-functions ]] || return 0
  fpath=("$brew_prefix/share/zsh/site-functions" $fpath)
}

_dotfiles_source_completions() {
  local file

  for file in "$DOTFILES"/completions/*.zsh(N); do
    source "$file"
  done
}

_dotfiles_prune_fpath() {
  local dir
  local -a existing_fpath

  for dir in $fpath; do
    [[ -d $dir ]] && existing_fpath+=("$dir")
  done

  fpath=("${existing_fpath[@]}")
}

typeset -gU fpath
_dotfiles_zsh_functions=/usr/share/zsh/${ZSH_VERSION%.*}/functions
fpath=("$HOME/.zfunc" $fpath)
[[ -d /opt/homebrew/share/zsh/functions ]] && fpath=(/opt/homebrew/share/zsh/functions $fpath)
[[ -d $_dotfiles_zsh_functions ]] && fpath=("$_dotfiles_zsh_functions" $fpath)
_zsh_profile_time "brew prefix" _dotfiles_brew_fpath
fpath=("$DOTFILES/completions" $fpath)
_zsh_profile_time "gh_source perlpunk/shell-completions" gh_source perlpunk/shell-completions \
  'fpath=("{}"/zsh $fpath)'
_dotfiles_prune_fpath
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

autoload -Uz compinit
_dotfiles_compdump=${ZDOTDIR:-$HOME}/.zcompdump
if [[ -s $_dotfiles_compdump ]]; then
  _zsh_profile_time "compinit -u -C" compinit -u -C -d "$_dotfiles_compdump"
else
  _zsh_profile_time "compinit -u" compinit -u -d "$_dotfiles_compdump"
fi
_zsh_profile_time "source $DOTFILES/completions" _dotfiles_source_completions
