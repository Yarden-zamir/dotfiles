# config for fzf
_dotfiles_source_fzf_zsh() {
    local -a restore_options
    local opt

    for opt in "${(@k)options}"; do
        [[ "$opt" == zle ]] && continue
        if [[ -o "$opt" ]]; then
            restore_options+=("-o" "$opt")
        else
            restore_options+=("+o" "$opt")
        fi
    done

    # fzf snapshots $options and tries to restore the unchangeable zle option.
    () {
        local -hA options
        source "$1"
    } "$1"

    setopt "${restore_options[@]}"
}

gh_source junegunn/fzf 'export PATH="${PATH:+$PATH:}{}/bin"; [[ $- == *i* ]] && _dotfiles_source_fzf_zsh {}/shell/completion.zsh; _dotfiles_source_fzf_zsh {}/shell/key-bindings.zsh'

unfunction _dotfiles_source_fzf_zsh
    # --bind 'tab:replace-query' \
export FZF_DEFAULT_OPTS=" \
    --bind 'bs:backward-delete-char/eof' \
    --bind 'ctrl-p:toggle-preview' \
    --bind 'alt-p:toggle-preview' \
    --bind 'ctrl-y:execute-silent(echo -n {} | pbcopy)' \
    --bind 'alt-up:half-page-up' \
    --bind 'alt-down:half-page-down' \
    --bind 'ctrl-a:toggle-all' \
    --bind 'alt-space:toggle+down' \
    --bind 'ctrl-space:toggle+down' \
    --bind 'alt-enter:toggle+down' \
    --height=100% \
    --no-separator \
    --info inline:'' \
    --prompt='🥔 ' \
    --border=rounded \
    --margin=0,0 \
    --ansi  \
    --preview-window 'wrap:right:55%' \
    --border-label=' 🥑 ' 
    --color=label:italic \
    --border-label-pos='1000:top' \
    --reverse  \
    -i \
    --no-scrollbar"

export FZF_CTRL_T_OPTS=" \
    --bind 'ctrl-o:become(code {})' \
    --preview '\
        ([ -d {} ] && erd {} 2> /dev/null || erd {} --hidden --no-git 2> /dev/null || echo {}) ||\
        bat --terminal-width \$(expr \$(tput cols) / 2 - 7) --wrap=character --color=always --style=header {}'"
# --preview '[ -d {} ] && et --dirs-first --icons --sort=name --scale=0 --level=4 {} || bat --terminal-width \$(expr \$(tput cols) / 2 - 7) --wrap=character --color=always --style=header --line-range :300 {}'"
export FZF_ALT_C_OPTS="
    $FZF_CTRL_T_OPTS
    "
export FZF_CTRL_R_OPTS=" \
    --preview 'echo {} | bat -pl zsh --color=always && explain {}'"

export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

fzf-file-or-folder-to-editor() {
    editor=${EDITOR:-code}
    choice="$(eval "$FZF_DEFAULT_COMMAND" | eval fzf "$FZF_CTRL_T_OPTS" | tr '\n' ' ')" && [[ ! -z $choice ]] &&
        $editor "$choice"
}

zle -N fzf-file-or-folder-to-editor fzf-file-or-folder-to-editor
