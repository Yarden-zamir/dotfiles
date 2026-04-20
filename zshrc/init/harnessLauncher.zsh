OPEN_HARNESS_PROGRAMS=(opencode claude codex)
open-harness() {
    # open current folder with a program selected with fzf
    local program
    program=$(echo -e "$OPEN_HARNESS_PROGRAMS" | tr ' ' '\n' | fzf --prompt "Open this folder with - ")
    case $program in
    opencode)
        opencode
        ;;
    claude)
        claude
        ;;
    codex)
        codex
        ;;
    *)
        $program 2>/dev/null
        ;;
    esac
}
zle -N open-harness open-harness
