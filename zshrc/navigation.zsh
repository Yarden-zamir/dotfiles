INDEX_FOLDERS=(~/Github ~/Desktop )

all_items=""
for folder in $INDEX_FOLDERS; do
    all_items+="$folder\n"
    all_items+="$(find $folder -type d -maxdepth 1 -mindepth 1 -printf "%p\n")\n"
done

navigate(){
    cd -- "$(echo -e $all_items | eval "fzf $FZF_CTRL_T_OPTS --with-nth=-1 --delimiter='/'")"
    zle accept-line
    BUFFER=""
}

zle -N navigate navigate

bindkey ^@ navigate #ctrl+space / ctrl+@

