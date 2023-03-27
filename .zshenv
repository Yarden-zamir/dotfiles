export DOTFILES="$HOME/Github/dotfiles"
folders=(
  "$DOTFILES/zshenv/pre-init" 
  "$DOTFILES/zshenv/init"
  "$DOTFILES/zshenv/post-init")
for folder in $folders; do
  (echo $folder/*) &> /dev/null && \
  for file in $folder/* ; do
    source "$file"
  done
done