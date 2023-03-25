# config for fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FZF_DEFAULT_OPTS=" \
    --bind 'bs:backward-delete-char/eof' \
    --bind 'ctrl-a:select-all' \
    --bind 'ctrl-p:toggle-preview' \
    --bind 'alt-up:half-page-up' \
    --bind 'alt-down:half-page-down' \
    --bind 'alt-d:replace-query' \
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
    --no-scrollbar"

export FZF_CTRL_T_OPTS=" \
    --hscroll-off 100 \
    --bind 'ctrl-o:execute(code {})' \
    --preview '\
        ([ -d {} ] && et --dirs-first --icons --sort=name --scale=0 --level=4 {}) ||\
        bat --terminal-width \$(expr \$(tput cols) / 2 - 7) --wrap=character --color=always --style=header {}'"
    # --preview '[ -d {} ] && et --dirs-first --icons --sort=name --scale=0 --level=4 {} || bat --terminal-width \$(expr \$(tput cols) / 2 - 7) --wrap=character --color=always --style=header --line-range :300 {}'"
export FZF_ALT_C_OPTS="
    $FZF_CTRL_T_OPTS
    "
export FZF_CTRL_R_OPTS="
    --preview 'x={} && x=\${x:7} && echo \$x&& explain \$x' \
    --scheme history
    --with-nth=2..
    --history-size=1000000
    --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'"


export PATH="$PATH:/opt/homebrew/bin"
export FZF_DEFAULT_COMMAND='fd --strip-cwd-prefix'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
bindkey '^f' fzf-file-widget

fzf_file_or_folder_to_editor() {
    editor=${EDITOR:-code}
    choice="$(eval $FZF_DEFAULT_COMMAND | eval fzf $FZF_CTRL_T_OPTS |tr '\n' ' ')" && [[ ! -z $choice ]] &&\
    $editor $choice
}

zle -N fzf_file_or_folder_to_editor fzf_file_or_folder_to_editor
bindkey '^o' fzf_file_or_folder_to_editor

# bindkey '^[[C' accept-search