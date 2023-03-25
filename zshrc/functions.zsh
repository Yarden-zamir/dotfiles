function mkcd() {
    mkdir -p "$@" && cd "$_"
}


function docker-stop-all(){
	docker stop $(docker ps -q)
}

function is_folder(){ # checks if $1 is a folder returns exit code 0 if true
    [ -d $1 ]
}

function set-shell(){
    chsh -s $(which $1)
}

function p(){  #executes python code
    prefix_code="import sys
from sys import stdin
"
    python3 -c $prefix_code$1
}

function calc(){ #calculates in the terminal
    bc -l <<< "scale=5; $@"
}

function is_interactive(){
    [[ $- == *i* ]]
}