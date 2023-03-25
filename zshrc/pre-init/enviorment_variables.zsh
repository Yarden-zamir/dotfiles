folders=(
  "$DOTFILES/zshrc/enviornment_variables" )
for folder in $folders; do
  for file in $folder/*; do
    source "$file"
  done
done