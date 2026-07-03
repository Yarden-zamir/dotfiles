export PATH="$PATH:/Users/kcw/Github/git-fuzzer"
git-branch() {
    git-fuzzer branch
}
zle -N git-branch git-branch

git-stage() {
    git-fuzzer stage
}
zle -N git-stage git-stage

git-history() {
   git-fuzzer history
}
zle -N git-history git-history

wt() {
    local target
    target="$($DOTFILES/bin/wt "$@")" || return
    [[ -n "$target" ]] && cd "$target"
}
