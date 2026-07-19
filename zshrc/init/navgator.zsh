# Homebrew-managed; enable exactly one setup path.
# source "$(brew --prefix navgator)/share/navgator/navgator.zsh"

# Local checkout managed by gh-source.
gh_source Yarden-zamir/navgator/scripts/navgator.zsh \
    --skip-build-if-present target/release/navgator \
    --build cargo build --release
