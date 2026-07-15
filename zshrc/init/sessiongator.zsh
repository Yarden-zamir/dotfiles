[[ -o interactive ]] && stty -ixon 2>/dev/null

gh_source Yarden-zamir/sessiongator/scripts/sessiongator.zsh \
    --skip-build-if-present target/release/sessiongator \
    --build cargo build --release
