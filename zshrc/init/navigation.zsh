INDEX_FOLDERS=(~/Github ~/Desktop )

all_items="$HOME/Desktop
/opt/homebrew
$HOME/Downloads
"
for folder in $INDEX_FOLDERS; do
    all_items+="$folder\n"
    all_items+="$(find $folder -type d -maxdepth 1 -mindepth 1 -printf "%p\n")\n"
done


navigate(){
    cd -- "$(echo -e $all_items | eval "fzf $FZF_CTRL_T_OPTS \
        --bind 'alt-d:become(cd {} && eval fzf \$FZF_CTRL_T_OPTS)' \
        --with-nth=-1 --delimiter='/'")"
    zle accept-line
    BUFFER=""
}

zle -N navigate navigate

