
function magic-enter-cmd {
    cmd="clear && exa --icons --all"
    if command git rev-parse --is-inside-work-tree &>/dev/null; then
        cmd=$cmd"&& git status -sb | bat --style=plain --language='Git Attributes'"
    fi
    echo $cmd
}
gh_source zshzoo/magic-enter/magic-enter.zsh