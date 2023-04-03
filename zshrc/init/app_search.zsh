function browse_apps(){ #opens an app fzf style
    cd /Applications
    app=$(ls | fzf)
    open $app
}

zle -N browse_apps browse_apps
