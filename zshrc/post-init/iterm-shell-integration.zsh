if [[ -o interactive && "$TERM_PROGRAM" == 'iTerm.app' ]]; then
    _iterm_shell_integration="$HOME/.iterm2_shell_integration.zsh"
    if [[ -r "$_iterm_shell_integration" ]]; then
        source "$_iterm_shell_integration"
    else
        print -u2 "iTerm shell integration is missing: $_iterm_shell_integration"
    fi
    unset _iterm_shell_integration
fi
