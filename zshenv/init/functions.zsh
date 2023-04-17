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
input = stdin.read().strip()
"
    python3 -c $prefix_code$1
}
function strman(){  # manipulates strings with python
    prefix_code="import sys
from sys import stdin
input = stdin.read().strip()
input = input. "
    user_code="$1
"
    suffix_code="print(input)"
    
    python3 -c $prefix_code$user_code$suffix_code
}

function calc(){ #calculates in the terminal
    bc -l <<< "scale=5; $@"
}

function is_interactive(){
    [[ $- == *i* ]]
}