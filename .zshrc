#!/usr/bin/env zsh

export DOTFILES="$HOME/Github/dotfiles/main"

folders=(
  "$DOTFILES/zshrc/pre-init"
  "$DOTFILES/zshrc/init"
  "$DOTFILES/zshrc/post-init"
)
_dotfiles_source_dir "${folders[@]}"
