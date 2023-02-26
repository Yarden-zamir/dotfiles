function mkcd() {
    mkdir -p "$@" && cd "$_"
}


function docker-stop-all(){
	docker stop $(docker ps -q)
}

function is_folder(){ # checks if $1 is a folder returns exit code 0 if true
    [ -d $1 ]
}

function create-nav-shortcuts() {   # creates shortcuts for all directories in $1 using prefix $2
    nav_base=$1
    nav_simbol=${2:-@}
    alias $nav_simbol$(basename $nav_base)="cd $nav_base"
    for dir in $nav_base/*; do if [[ -d $dir ]]; then
        dirname=$(basename $dir)
        alias $nav_simbol$dirname="cd $dir;"
    fi; done
    # ls $nav_base | xargs -I% sh -c "is_folder % && alias $nav_simbol%=\"cd $nav_base/%\"||:"

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

function calc(){ #calculates in the terminal
    bc -l <<< "scale=5; $@"
}