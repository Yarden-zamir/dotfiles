export DOTFILES="$HOME/Github/dotfiles"
folders=(
  "$DOTFILES/zshrc/pre-init" 
  "$DOTFILES/zshrc"
  "$DOTFILES/zshrc/post-init")
for folder in $folders; do
  for file in $folder/*; do
    source "$file"
  done
done