INDEX_FOLDERS=(~/Github ~/Desktop)
all_items="$HOME/Desktop
/opt/homebrew
$HOME/Downloads
/Users/kcw/Library/Application Support/com.modrinth.theseus/profiles/Create-Prepare-to-Dye
"
templates="yarden-zamir/python-template
yarden-zamir/dotnet-template
qlik-trial/dotnet-service
Computer-Engineering-Major-Ort-Ariel/WebTemplate"

for folder in $INDEX_FOLDERS; do
    all_items+="$folder\n"
    all_items+="$(find "$folder" -maxdepth 1 -mindepth 1 -type d -printf "%p\n")\n"
done

navigate() {
    cd -- "$(echo -e "$all_items" | eval "fzf $FZF_CTRL_T_OPTS \
        --bind 'alt-d:become(cd {} && eval fzf \$FZF_CTRL_T_OPTS)' \
        --with-nth=-1 --delimiter='/'")" || exit
    zle accept-line
    BUFFER=""
}

zle -N navigate navigate

context() {
    local context_name=$1
    for item in $(echo -e "$all_items"); do
        if [[ $item == *"$context_name" ]]; then
            cd "$item" || return 1
            return 0
        fi
    done

    local template=${2:-$(echo "$templates" | fzf --prompt "Select a template")}
    local description=${3:-$context_name}
    cd "${INDEX_FOLDERS[1]}" || return 1
    gh repo create "$context_name" --clone --description "$description" --disable-wiki --public --template "$template"
    cd "$context_name" || return 1
    if [[ -f .envrc ]]; then
        direnv allow
    fi
    if [[ -f .mise.toml ]]; then
        mise trust
        mise run dependency-setup || true
        touch .mise.local.toml
    fi
}
