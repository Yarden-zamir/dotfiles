_binds_parse_bindkey_lines() {
    local line binding widget

    while IFS= read -r line; do
        [[ -n "$line" ]] || continue

        widget="${line##* }"
        binding="${line% $widget}"
        print -r -- "$binding	$widget"
    done
}

_binds_default_mode_for_keymap() {
    local keymap="$1"

    if [[ "$keymap" == viins || "$keymap" == vicmd ]]; then
        print -r -- "-v"
    else
        print -r -- "-e"
    fi
}

_binds_default_entries() {
    local keymap="$1"
    local mode="$(_binds_default_mode_for_keymap "$keymap")"

    command zsh -f -c 'bindkey "$1"; bindkey -M "$2" 2>/dev/null' zsh "$mode" "$keymap" |
        _binds_parse_bindkey_lines
}

_binds_current_entries() {
    local keymap="$1"

    bindkey -M "$keymap" 2>/dev/null | _binds_parse_bindkey_lines
}

_binds_key_label() {
    local binding="$1"
    local key="$binding"

    if [[ "$key" == \"*\" ]]; then
        key="${key#\"}"
        key="${key%\"}"
    fi

    key="${key//\^\[/Alt+}"
    key="${key//\^/Ctrl+}"
    key="${key//Ctrl+@/Ctrl+Space}"
    key="${key//Ctrl+I/Tab}"
    key="${key//Ctrl+M/Enter}"
    key="${key//Ctrl+\?/Backspace}"
    print -r -- "$key"
}

binds() {
    emulate -L zsh

    local scope="${1:-mine}"
    local keymap="${2:-${KEYMAP:-main}}"

    if [[ "$scope" != "mine" && "$scope" != "all" ]]; then
        keymap="$scope"
        scope="mine"
    fi

    local -a keymaps
    if [[ "$keymap" == "all" ]]; then
        keymaps=( ${(f)"$(bindkey -l)"} )
    else
        keymaps=( "$keymap" )
    fi

    {
        print -r -- "KEYMAP	KEY	RAW	WIDGET"

        local map binding widget
        for map in "${keymaps[@]}"; do
            if ! bindkey -M "$map" >/dev/null 2>&1; then
                print -ru2 -- "binds: unknown keymap: $map"
                continue
            fi

            local -A defaults=()
            while IFS=$'\t' read -r binding widget; do
                [[ -n "$binding" ]] || continue
                defaults[$binding]="$widget"
            done < <(_binds_default_entries "$map")

            while IFS=$'\t' read -r binding widget; do
                [[ -n "$binding" ]] || continue
                if [[ "$scope" == "mine" && "${defaults[$binding]-}" == "$widget" ]]; then
                    continue
                fi

                print -r -- "$map	$(_binds_key_label "$binding")	$binding	$widget"
            done < <(_binds_current_entries "$map")
        done
    } | if command -v column >/dev/null 2>&1; then
        column -t -s $'\t'
    else
        cat
    fi
}
