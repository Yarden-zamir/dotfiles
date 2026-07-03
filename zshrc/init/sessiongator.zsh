[[ -o interactive ]] && stty -ixon 2>/dev/null

# gh_source Yarden-zamir/sessiongator 'prefix="$(brew --prefix sessiongator 2>/dev/null)" && source "$prefix/share/sessiongator/sessiongator.zsh"'
gh_source Yarden-zamir/sessiongator 'repo="{}"; [ -f "$repo/main/Cargo.toml" ] && repo="$repo/main"; if [ -f "$repo/target/release/sessiongator" ]; then source "$repo/scripts/sessiongator.zsh"; else cd "$repo" && cargo build --release && source "$repo/scripts/sessiongator.zsh"; fi'
