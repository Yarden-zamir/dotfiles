# Search for files using names and content glob patterns (unlike the usual aproach of just content)
ripgrep_search(){
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
        --bind 'enter:become(code --goto {1}:{2})' \
        --prompt '1. ripgrep> ' \
        --header 'CTRL-F/R to swich modes' \
        --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
        --bind "ctrl-r:unbind(change,ctrl-f)+change-prompt(2. fzf> )+enable-search+rebind(ctrl-r)+transform-query(echo {q} > /tmp/rg-fzf-r; cat /tmp/rg-fzf-f)" \
        --bind "ctrl-r:unbind(ctrl-r)+change-prompt(1. ripgrep> )+disable-search+reload($RG_PREFIX {q} || true)+rebind(change,ctrl-f)+transform-query(echo {q} > /tmp/rg-fzf-f; cat /tmp/rg-fzf-r)" \
        --bind "start:unbind(ctrl-r)" \

}
zle -N ripgrep_search ripgrep_search
