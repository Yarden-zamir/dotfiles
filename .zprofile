# Added by Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

folders=(
  "$DOTFILES/zprofile/pre-init"
  "$DOTFILES/zprofile/init"
  "$DOTFILES/zprofile/post-init"
)
_dotfiles_source_dir "${folders[@]}"
