type -p direnv &>/dev/null && {
    function venv-direnv() {
        [[ -d .venv ]] || python3 -m venv .venv
        [[ -f .envrc ]] || echo 'source .venv/bin/activate' > .envrc
        direnv allow
    }
}