OPEN_HARNESS_PROGRAMS=(opencode claude codex copilot)
open-harness() {
    # open current folder with a program selected with fzf
    local program

    zle -I
    program=$(printf '%s\n' "${OPEN_HARNESS_PROGRAMS[@]}" | fzf --prompt "Open this folder with - ") || return
    [[ -n "$program" ]] || return

    BUFFER="$program"
    CURSOR=${#BUFFER}
    zle accept-line
}
zle -N open-harness open-harness
