# Bash for coding agents. Interactive use stays in zsh.
# BASH_ENV loads this file for every bash script, so skip it outside agents.
[[ $- == *i* || -n ${CLAUDECODE-}${OPENCODE-}${COPILOT_CLI-} ]] || return 0

export DOTFILES="$HOME/Github/dotfiles/main"

_dotfiles_source_dir() {
    local folder file
    for folder in "$@"; do
        [[ -d $folder ]] || continue
        for file in "$folder"/*.bash; do
            [[ -f $file ]] && source "$file"
        done
    done
}

_dotfiles_source_dir \
    "$DOTFILES/bashrc/pre-init" \
    "$DOTFILES/bashrc/init" \
    "$DOTFILES/bashrc/post-init"
