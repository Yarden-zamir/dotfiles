export DOTFILES="$HOME/Github/dotfiles"
# export ZSH_PROFILE=0
_dotfiles_source_dir() {
  local folder file
  local -F start end elapsed total
  local use_epoch=0

  if [[ -n ${ZSH_PROFILE-} ]]; then
    zmodload zsh/datetime 2>/dev/null && use_epoch=1
  fi

  for folder in "$@"; do
    [[ -d $folder ]] || continue
    total=0

    for file in "$folder"/*.zsh(N); do
      [[ -f $file ]] || continue

      if [[ -n ${ZSH_PROFILE-} ]]; then
        if (( use_epoch )); then
          start=$EPOCHREALTIME
          source "$file"
          end=$EPOCHREALTIME
          elapsed=$(( end - start ))
        else
          start=$SECONDS
          source "$file"
          end=$SECONDS
          elapsed=$(( end - start ))
        fi

        total=$(( total + elapsed ))
        printf 'zsh-profile: %.6fs %s\n' "$elapsed" "$file" >&2
      else
        source "$file"
      fi
    done

    if [[ -n ${ZSH_PROFILE-} ]]; then
      printf 'zsh-profile: %.6fs total %s\n' "$total" "$folder" >&2
    fi
  done
}

folders=(
  "$DOTFILES/zshenv/pre-init"
  "$DOTFILES/zshenv/init"
  "$DOTFILES/zshenv/post-init"
)
_dotfiles_source_dir "${folders[@]}"
# . "$HOME/.cargo/env"
