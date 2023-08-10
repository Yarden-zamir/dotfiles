
function magic-enter-cmd {
    [ $(ls | wc -l) -gt 15 ] && {
        cmd=" clear && exa --icons --all" 
    } || {
        cmd=" clear && exa --icons --all --long --git --no-permissions --no-user --no-time --group-directories-first"
    }

    if command git rev-parse --is-inside-work-tree &>/dev/null; then
        cmd=$cmd"&& git status -sb | bat --style=plain --language='Git Attributes'"
    fi
    echo $cmd
}
gh_source zshzoo/magic-enter/magic-enter.plugin.zsh