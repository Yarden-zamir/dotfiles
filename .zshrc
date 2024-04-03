#! /bin/bash

export DOTFILES="$HOME/Github/dotfiles"
folders=(
  "$DOTFILES/zshrc/pre-init"
  "$DOTFILES/zshrc/init"
  "$DOTFILES/zshrc/post-init")
for folder in $folders; do
  (echo $folder/*) &>/dev/null &&
    for file in "${folder}"/*; do
      [[ $file == *.zsh ]] && source "$file"
    done
done
