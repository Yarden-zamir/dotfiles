OPEN_WITH_PROGRAMS=(code open github rider github-online)
open-with() {
    # open current folder with a program selected with fzf
    local program
    program=$(echo -e "$OPEN_WITH_PROGRAMS" | tr ' ' '\n' | fzf --prompt "Open this folder with - ")
    case $program in
    code)
        code -r .
        ;;
    github-online)
        gh repo view --web
        ;;
    *)
        $program . 2>/dev/null
        ;;
    esac
}
open-with-code() {
    code -r .
}
zle -N open-with open-with
zle -N open-with-code open-with-code
