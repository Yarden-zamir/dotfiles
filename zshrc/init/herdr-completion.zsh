# herdr zsh completion. Generated from the installed binary and cached
# until that binary changes, because the fork build is rebuilt often.
# Runs after compinit (pre-init), so register the function explicitly.
() {
    (( $+commands[herdr] )) || return 0
    local cache=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions
    local file=$cache/_herdr
    if [[ ! -s $file || $file -ot $commands[herdr] ]]; then
        mkdir -p "$cache" && herdr completion zsh >| "$file"
    fi
    fpath=("$cache" $fpath)
    autoload -Uz _herdr && compdef _herdr herdr
}
