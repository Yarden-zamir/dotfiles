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
