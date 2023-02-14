function mkcd() {
    mkdir -p "$@" && cd "$_"
}


function docker-stop-all(){
	docker stop $(docker ps -q)
}

function create-nav-shortcuts() {   # creates shortcuts for all directories in $1 using prefix $2
    nav_base=$1
    nav_simbol=${2:-@}
    cd $nav_base
    alias $nav_simbol$(basename $nav_base)="cd $nav_base"
    for dir in *; do if [[ -d $dir ]]; then
        alias $nav_simbol$dir="cd $nav_base/$dir;"
    fi; done
}

function set-shell(){
    chsh -s $(which $1)
}

function p(){  #executes python code
    prefix_code="import sys
from sys import stdin
"
    # echo $prefix_code $1 
    python3 -c $prefix_code$1
    # python3 -c $prefix_code $1

}

function a(){ #opens an app fzf style
    cd /Applications
    app=$(ls | fzf)
    open $app
}