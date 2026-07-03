gh_source Yarden-zamir/navgator 'repo="{}"; [ -f "$repo/main/Cargo.toml" ] && repo="$repo/main"; if command -v navgator >/dev/null 2>&1 || [ -f "$repo/target/release/navgator" ]; then source "$repo/scripts/navgator.zsh"; else cd "$repo" && cargo build --release && source "$repo/scripts/navgator.zsh"; fi'
# gh_source junegunn/fzf '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh || {}/install'
