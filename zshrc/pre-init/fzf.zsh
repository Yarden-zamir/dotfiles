# config for fzf
gh_source junegunn/fzf '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh || {}/install'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS=" \
    --bind 'bs:backward-delete-char/eof' \
    --bind 'ctrl-p:toggle-preview' \
    --bind 'alt-p:toggle-preview' \
    --bind 'ctrl-y:execute-silent(echo -n {} | pbcopy)' \
    --bind 'alt-up:half-page-up' \
    --bind 'alt-down:half-page-down' \
    --bind 'tab:replace-query' \
    --bind 'ctrl-a:toggle-all' \
    --bind 'alt-space:toggle+down' \
    --bind 'ctrl-space:toggle+down' \
    --bind 'alt-enter:toggle+down' \
    --height=100% \
    --multi  \
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
        ([ -d {} ] && erd {} 2> /dev/null || erd {} --hidden --no-git) ||\
        bat --terminal-width \$(expr \$(tput cols) / 2 - 7) --wrap=character --color=always --style=header {}'"
# --preview '[ -d {} ] && et --dirs-first --icons --sort=name --scale=0 --level=4 {} || bat --terminal-width \$(expr \$(tput cols) / 2 - 7) --wrap=character --color=always --style=header --line-range :300 {}'"
export FZF_ALT_C_OPTS="
    $FZF_CTRL_T_OPTS
    "
export FZF_CTRL_R_OPTS=" \
    --preview 'echo {} | bat -pl zsh --color=always && explain {}'"

export PATH="$PATH:/opt/homebrew/bin"
export FZF_DEFAULT_COMMAND='fd --hidden --strip-cwd-prefix'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

fzf-file-or-folder-to-editor() {
    editor=${EDITOR:-code}
    choice="$(eval "$FZF_DEFAULT_COMMAND" | eval fzf "$FZF_CTRL_T_OPTS" | tr '\n' ' ')" && [[ ! -z $choice ]] &&
        $editor "$choice"
}

zle -N fzf-file-or-folder-to-editor fzf-file-or-folder-to-editor
