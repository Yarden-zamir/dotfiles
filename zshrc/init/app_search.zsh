function open_app(){ #opens an app fzf style
    cd /Applications
    app=$(ls | fzf)
    open $app
}

zle -N open_app open_app

bindkey '^a' open_app