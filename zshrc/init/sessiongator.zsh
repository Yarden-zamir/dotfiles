[[ -o interactive ]] && stty -ixon 2>/dev/null

# Homebrew-managed; enable exactly one setup path.
# source "$(brew --prefix sessiongator)/share/sessiongator/sessiongator.zsh"

# Local checkout managed by gh-source.
gh_source Yarden-zamir/sessiongator/scripts/sessiongator.zsh \
    --skip-build-if-present target/release/sessiongator \
    --build cargo build --release
