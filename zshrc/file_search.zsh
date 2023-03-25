# Search for files using names and content glob patterns (unlike the usual aproach of just content)
file_search(){
    RG_PREFIX="rg --ignore-file='$HOME/Library/*' --ignore-file='/Library/*'--column --line-number --no-heading --color=always --dfa-size-limit 2G --smart-case "
    RG_PREFIX_filenames="$RG_PREFIX --max-count=1 '' --glob-case-insensitive --glob"

    INITIAL_QUERY="$1"
    FZF_DEFAULT_COMMAND="$RG_PREFIX $(printf %q "$INITIAL_QUERY")" \
    fzf --ansi \
        --disabled --query "$INITIAL_QUERY" \
        --bind "change:reload:sleep 0.1; $RG_PREFIX_filenames '*{q}*' & $RG_PREFIX {q} || true" \
        --delimiter : \
        --preview 'bat --color=always --style=changes,header,header-filename,numbers,rule,snip {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind 'enter:become(code --goto {1}:{2})'
}
zle -N file_search file_search

bindkey '^[ ' file_search #alt+space