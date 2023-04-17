type -p direnv &>/dev/null && {
    function venv-direnv() {
        [[ -f .envrc ]] || echo '#! /bin/sh \nlayout python python3' > .envrc
        direnv allow
    }
}