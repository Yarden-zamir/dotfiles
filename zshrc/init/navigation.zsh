INDEX_FOLDERS=(~/Github ~/Desktop)

all_items="$HOME/Desktop
/opt/homebrew
$HOME/Downloads
/Users/kcw/Library/Application Support/com.modrinth.theseus/profiles/Create-Prepare-to-Dye
"
for folder in $INDEX_FOLDERS; do
    all_items+="$folder\n"
    all_items+="$(find "$folder" -maxdepth 1 -mindepth 1 -type d -printf "%p\n")\n"
done

navigate() {
    cd -- "$(echo -e "$all_items" | eval "fzf $FZF_CTRL_T_OPTS \
        --bind 'alt-d:become(cd {} && eval fzf \$FZF_CTRL_T_OPTS)' \
        --with-nth=-1 --delimiter='/'")" || exit
    zle accept-line
    # shellcheck disable=SC2034
    BUFFER=""
}

zle -N navigate navigate
