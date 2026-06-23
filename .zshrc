#! /bin/bash

export DOTFILES="$HOME/Github/dotfiles"

folders=(
  "$DOTFILES/zshrc/pre-init"
  "$DOTFILES/zshrc/init"
  "$DOTFILES/zshrc/post-init"
)
_dotfiles_source_dir "${folders[@]}"

# zprof
