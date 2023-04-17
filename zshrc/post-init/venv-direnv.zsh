type -p direnv &>/dev/null && {
    function venv-direnv() {
        [[ -f .envrc ]] || echo 'layout python python3' > .envrc
        direnv allow
    }
}