# Editor-like navigation, selection, deletion, clipboard, and undo for ZLE.
#
# Dependencies:
# - zsh's ZLE module.
# - Optional: zsh-autopair must load before this file; its behavior is preserved.
# - Optional clipboard tools: pbcopy, wl-copy, or xclip. OSC 52 is the fallback.
#
# Terminal requirements:
# - Shift/Option arrows should send xterm sequences or ESC b/f for Option Left/Right.
# - Command arrows should send xterm Super-arrow sequences.
# - Command+Backspace should send ^U for shell and TUI compatibility.
# - Command+Delete and physical Ctrl+K should use the standard ^K behavior.
# - Shift+Command arrows should send CSI 1;10 A/B/C/D.
# - Command letters should use CSI-u Super events (modifier 9 or 10).
# - Older CSI 99~ commands remain accepted for compatibility.
# - Command+V should remain the terminal's native bracketed paste action.
# - Ctrl+Enter should send ^J (CSI 13;5u is also accepted).
# - Fixed terminal mappings are global to that profile; full-screen apps may
#   receive the private sequences when they claim the same Command shortcuts.
#
# Load this after plugins and other key bindings. Canonical insertion/deletion
# widgets and optional autopair widgets are saved before wrapping. The
# installation guard makes manual re-sourcing safe.

[[ -o interactive ]] || return 0
zmodload zsh/zle 2>/dev/null || return 0

if (( ${_ZLE_EDITOR_INSTALLED:-0} )); then
    return 0
fi
typeset -gi _ZLE_EDITOR_INSTALLED=1

# VS Code's default ASCII word separators. Whitespace is handled separately.
typeset -gr ZLE_EDITOR_WORD_SEPARATORS=$'`~!@#$%^&*()-=+[{]}\\|;:\'\",.<>/?'
typeset -gA _zle_editor_word_separator_map
typeset -g _zle_editor_word_type _zle_editor_word_next_class
typeset -gi _zle_editor_word_start _zle_editor_word_end

if (( ${#_zle_editor_word_separator_map} == 0 )); then
    for _zle_editor_char in ${(s::)ZLE_EDITOR_WORD_SEPARATORS}; do
        _zle_editor_word_separator_map[$_zle_editor_char]=1
    done
    unset _zle_editor_char
fi

_zle_editor_has_region() {
    (( REGION_ACTIVE && MARK != CURSOR ))
}

_zle_editor_region_bounds() {
    if (( MARK < CURSOR )); then
        reply=( $MARK $CURSOR )
    else
        reply=( $CURSOR $MARK )
    fi
}

# Delete the active half-open region without changing the clipboard or kill ring.
_zle_editor_delete_region() {
    emulate -L zsh

    if ! _zle_editor_has_region; then
        if (( REGION_ACTIVE )); then
            REGION_ACTIVE=0
            MARK=$CURSOR
        fi
        return 1
    fi

    local -a reply
    _zle_editor_region_bounds
    local start=$reply[1]
    local end=$reply[2]

    BUFFER="${BUFFER[1,start]}${BUFFER[end+1,-1]}"
    CURSOR=$start
    MARK=$CURSOR
    REGION_ACTIVE=0
    return 0
}

_zle_editor_refresh_suggestion() {
    (( ${+widgets[autosuggest-fetch]} )) || return 0

    if (( ${+_ZSH_AUTOSUGGEST_DISABLED} )) || [[ -z $BUFFER ]] ||
       { [[ -n ${ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE-} ]] &&
         (( ${#BUFFER} > ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE )); }; then
        zle autosuggest-clear
    else
        zle autosuggest-fetch
    fi
}

_zle_editor_region_text() {
    emulate -L zsh
    _zle_editor_has_region || return 1

    local -a reply
    _zle_editor_region_bounds
    REPLY=${BUFFER[reply[1]+1,reply[2]]}
}

_zle_editor_begin_region() {
    if (( ! REGION_ACTIVE )); then
        zle set-mark-command
    fi
}

_zle_editor_select_with() {
    _zle_editor_begin_region
    zle "$1"
}

_zle_editor_deactivate_region() {
    if (( REGION_ACTIVE )); then
        zle deactivate-region
    fi
    MARK=$CURSOR
}

_zle_editor_collapse_left() {
    if _zle_editor_has_region; then
        (( MARK < CURSOR )) && CURSOR=$MARK
        _zle_editor_deactivate_region
        return 0
    fi

    _zle_editor_deactivate_region
    return 1
}

_zle_editor_collapse_right() {
    if _zle_editor_has_region; then
        (( MARK > CURSOR )) && CURSOR=$MARK
        _zle_editor_deactivate_region
        return 0
    fi

    _zle_editor_deactivate_region
    return 1
}

# Store the next word or separator run in the shared scan result variables.
_zle_editor_scan_next_word() {
    emulate -L zsh
    local buf=$1
    local pos=$2
    local len=${#buf}
    local type=''
    local start=0
    local i char class

    for (( i=pos; i<len; i++ )); do
        char=${buf[i+1]}
        if [[ $char == [[:space:]] ]]; then
            if [[ -n $type ]]; then
                _zle_editor_word_start=$start
                _zle_editor_word_end=$i
                _zle_editor_word_type=$type
                _zle_editor_word_next_class=ws
                return 0
            fi
            continue
        fi

        if (( ${+_zle_editor_word_separator_map[$char]} )); then
            class=sep
        else
            class=word
        fi

        if [[ -z $type ]]; then
            type=$class
            start=$i
        elif [[ $type != $class ]]; then
            _zle_editor_word_start=$start
            _zle_editor_word_end=$i
            _zle_editor_word_type=$type
            _zle_editor_word_next_class=$class
            return 0
        fi
    done

    [[ -n $type ]] || return 1
    _zle_editor_word_start=$start
    _zle_editor_word_end=$len
    _zle_editor_word_type=$type
    _zle_editor_word_next_class=ws
}

_zle_editor_scan_previous_word() {
    emulate -L zsh
    local buf=$1
    local pos=$2
    local type=''
    local end=0
    local i char class

    for (( i=pos; i>=0; i-- )); do
        char=${buf[i+1]}
        if [[ $char == [[:space:]] ]]; then
            if [[ -n $type ]]; then
                _zle_editor_word_start=$(( i + 1 ))
                _zle_editor_word_end=$end
                _zle_editor_word_type=$type
                _zle_editor_word_next_class=ws
                return 0
            fi
            continue
        fi

        if (( ${+_zle_editor_word_separator_map[$char]} )); then
            class=sep
        else
            class=word
        fi

        if [[ -z $type ]]; then
            type=$class
            end=$(( i + 1 ))
        elif [[ $type != $class ]]; then
            _zle_editor_word_start=$(( i + 1 ))
            _zle_editor_word_end=$end
            _zle_editor_word_type=$type
            _zle_editor_word_next_class=$class
            return 0
        fi
    done

    [[ -n $type ]] || return 1
    _zle_editor_word_start=0
    _zle_editor_word_end=$end
    _zle_editor_word_type=$type
    _zle_editor_word_next_class=ws
}

# Match VS Code's word-right behavior: stop at a word end, but skip a single
# separator when it directly precedes another word.
_zle_editor_word_right() {
    emulate -L zsh
    local len=${#BUFFER}
    local pos=$CURSOR

    (( pos < len )) || return 0
    if ! _zle_editor_scan_next_word "$BUFFER" $pos; then
        CURSOR=$len
        return 0
    fi

    if [[ $_zle_editor_word_type == sep ]] &&
       (( _zle_editor_word_end - _zle_editor_word_start == 1 )) &&
       [[ $_zle_editor_word_next_class == word ]]; then
        _zle_editor_scan_next_word "$BUFFER" $_zle_editor_word_end || {
            CURSOR=$len
            return 0
        }
    fi

    CURSOR=$_zle_editor_word_end
}

_zle_editor_word_left() {
    emulate -L zsh
    (( CURSOR > 0 )) || return 0

    if _zle_editor_scan_previous_word "$BUFFER" $(( CURSOR - 1 )); then
        CURSOR=$_zle_editor_word_start
    else
        CURSOR=0
    fi
}

_zle_editor_line_start() {
    emulate -L zsh
    local pos=${1:-$CURSOR}
    local char

    while (( pos > 0 )); do
        char=${BUFFER[pos]}
        [[ $char == $'\n' || $char == $'\r' ]] && break
        (( pos-- ))
    done
    REPLY=$pos
}

_zle_editor_line_end() {
    emulate -L zsh
    local pos=${1:-$CURSOR}
    local len=${#BUFFER}
    local char

    while (( pos < len )); do
        char=${BUFFER[pos+1]}
        [[ $char == $'\n' || $char == $'\r' ]] && break
        (( pos++ ))
    done
    REPLY=$pos
}

# Selection widgets.
_zle_editor_select_left() { _zle_editor_begin_region; zle .backward-char }
_zle_editor_select_right() { _zle_editor_begin_region; zle .forward-char }
_zle_editor_select_up() { _zle_editor_begin_region; zle .up-line }
_zle_editor_select_down() { _zle_editor_begin_region; zle .down-line }
_zle_editor_select_word_left() { _zle_editor_select_with _zle_editor_word_left }
_zle_editor_select_word_right() { _zle_editor_select_with _zle_editor_word_right }
_zle_editor_select_line_start() {
    _zle_editor_begin_region
    _zle_editor_line_start
    CURSOR=$REPLY
}
_zle_editor_select_line_end() {
    _zle_editor_begin_region
    _zle_editor_line_end
    CURSOR=$REPLY
}
_zle_editor_select_buffer_start() {
    _zle_editor_begin_region
    CURSOR=0
}
_zle_editor_select_buffer_end() {
    _zle_editor_begin_region
    CURSOR=${#BUFFER}
}

_zle_editor_select_all() {
    if [[ -n $BUFFER ]]; then
        MARK=0
        CURSOR=${#BUFFER}
        REGION_ACTIVE=1
    else
        MARK=0
        CURSOR=0
        REGION_ACTIVE=0
    fi
}

# Movement widgets. Left/right motions collapse a selection to its boundary;
# explicit line/buffer motions still perform their requested destination move.
_zle_editor_move_left() { _zle_editor_collapse_left || zle backward-char }
_zle_editor_move_right() { _zle_editor_collapse_right || zle forward-char }
_zle_editor_move_up() { _zle_editor_deactivate_region; zle up-line }
_zle_editor_move_down() { _zle_editor_deactivate_region; zle down-line }
_zle_editor_move_word_left() { _zle_editor_collapse_left || zle _zle_editor_word_left }
_zle_editor_move_word_right() {
    _zle_editor_collapse_right || zle _zle_editor_word_right
}
_zle_editor_move_line_start() {
    _zle_editor_deactivate_region
    _zle_editor_line_start
    CURSOR=$REPLY
}
_zle_editor_move_line_end() {
    _zle_editor_deactivate_region
    _zle_editor_line_end
    CURSOR=$REPLY
}
_zle_editor_move_buffer_start() {
    _zle_editor_deactivate_region
    CURSOR=0
}
_zle_editor_move_buffer_end() {
    _zle_editor_deactivate_region
    CURSOR=${#BUFFER}
}

# Prefer movement inside a multiline buffer even while viewing a history entry.
# Only delegate to history-substring-search at the first or last logical line.
_zle_editor_recall_history() {
    emulate -L zsh
    local widget=$1
    local previous_buffer=$BUFFER
    # The plugin otherwise redraws at the buffer end and waits for the next key
    # before this wrapper can restore the first-line editing position.
    local HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_TIMEOUT=0

    _zle_editor_line_start
    local -i column=$(( CURSOR - REPLY ))
    zle "$widget"

    # The plugin always jumps to the result's end. Start on its first line at
    # the previous visual column so multiline entries remain easy to browse.
    if [[ $BUFFER != $previous_buffer ]]; then
        _zle_editor_line_end 0
        (( column > REPLY )) && column=$REPLY
        CURSOR=$column
        zle -R
    fi
}

_zle_editor_up_or_history() {
    _zle_editor_deactivate_region
    _zle_editor_line_start
    if (( REPLY > 0 )); then
        zle .up-line
    elif (( ${+widgets[history-substring-search-up]} )); then
        _zle_editor_recall_history history-substring-search-up
    else
        _zle_editor_recall_history .up-history
    fi
}

_zle_editor_down_or_history() {
    _zle_editor_deactivate_region
    _zle_editor_line_end
    if (( REPLY < ${#BUFFER} )); then
        zle .down-line
    elif (( ${+widgets[history-substring-search-down]} )); then
        _zle_editor_recall_history history-substring-search-down
    else
        _zle_editor_recall_history .down-history
    fi
}

# Wrappers preserve each original widget when no selection is active.
_zle_editor_self_insert() {
    _zle_editor_delete_region >/dev/null
    zle _zle_editor_saved_self_insert
}

_zle_editor_quoted_insert() {
    _zle_editor_delete_region >/dev/null
    zle _zle_editor_saved_quoted_insert
}

_zle_editor_yank() {
    _zle_editor_delete_region >/dev/null
    zle _zle_editor_saved_yank
}

_zle_editor_backward_delete_char() {
    _zle_editor_delete_region && return 0
    zle _zle_editor_saved_backward_delete_char
}

_zle_editor_delete_char() {
    _zle_editor_delete_region && return 0
    zle _zle_editor_saved_delete_char
}

_zle_editor_autopair_insert() {
    _zle_editor_delete_region >/dev/null
    zle _zle_editor_saved_autopair_insert
}

_zle_editor_autopair_close() {
    _zle_editor_delete_region >/dev/null
    zle _zle_editor_saved_autopair_close
}

_zle_editor_autopair_delete() {
    _zle_editor_delete_region && return 0
    zle _zle_editor_saved_autopair_delete
}

_zle_editor_autopair_delete_word() {
    if ! _zle_editor_delete_region; then
        zle _zle_editor_saved_autopair_delete_word
    fi
    _zle_editor_refresh_suggestion
}

_zle_editor_delete_word_left() {
    if _zle_editor_delete_region; then
        _zle_editor_refresh_suggestion
        return 0
    fi
    (( CURSOR > 0 )) || return 0

    local end=$CURSOR
    _zle_editor_word_left
    MARK=$end
    REGION_ACTIVE=1
    zle .kill-region
    REGION_ACTIVE=0
    MARK=$CURSOR
    _zle_editor_refresh_suggestion
}

_zle_editor_delete_word_right() {
    if _zle_editor_delete_region; then
        _zle_editor_refresh_suggestion
        return 0
    fi
    (( CURSOR < ${#BUFFER} )) || return 0

    local start=$CURSOR
    _zle_editor_word_right
    MARK=$start
    REGION_ACTIVE=1
    zle .kill-region
    REGION_ACTIVE=0
    MARK=$CURSOR
    _zle_editor_refresh_suggestion
}

_zle_editor_delete_line_start() {
    emulate -L zsh
    if _zle_editor_delete_region; then
        _zle_editor_refresh_suggestion
        return 0
    fi
    (( CURSOR > 0 )) || return 0

    _zle_editor_line_start
    local start=$REPLY

    (( start < CURSOR )) || return 0
    MARK=$start
    REGION_ACTIVE=1
    zle .kill-region
    REGION_ACTIVE=0
    MARK=$CURSOR
    _zle_editor_refresh_suggestion
}

_zle_editor_delete_line_end() {
    emulate -L zsh
    if _zle_editor_delete_region; then
        _zle_editor_refresh_suggestion
        return 0
    fi
    local len=${#BUFFER}
    (( CURSOR < len )) || return 0

    _zle_editor_line_end
    local end=$REPLY

    # At the line boundary, delete the newline and join the next line.
    if (( end == CURSOR && end < len )); then
        if [[ ${BUFFER[end+1]} == $'\r' && ${BUFFER[end+2]-} == $'\n' ]]; then
            (( end += 2 ))
        else
            (( end++ ))
        fi
    fi
    (( end > CURSOR )) || return 0
    MARK=$CURSOR
    CURSOR=$end
    REGION_ACTIVE=1
    zle .kill-region
    REGION_ACTIVE=0
    MARK=$CURSOR
    _zle_editor_refresh_suggestion
}

_zle_editor_insert_newline() {
    _zle_editor_delete_region >/dev/null
    LBUFFER+=$'\n'
}

_zle_editor_undo() {
    _zle_editor_deactivate_region
    zle undo
}

_zle_editor_redo() {
    _zle_editor_deactivate_region
    zle redo
}

_zle_editor_copy_osc52() {
    emulate -L zsh
    setopt localoptions pipefail
    (( ${+commands[base64]} && ${+commands[tr]} )) || return 1

    local encoded
    encoded=$(print -rn -- "$1" | command base64 | command tr -d '\r\n') || return 1

    if zmodload zsh/terminfo 2>/dev/null && [[ -n ${terminfo[Ms]-} ]]; then
        echoti Ms c "$encoded"
    else
        print -rn -- $'\e]52;c;'"$encoded"$'\e\\'
    fi
}

_zle_editor_clipboard_copy() {
    emulate -L zsh
    local text=$1

    # Remote shells should target the local terminal clipboard, not the remote host.
    if [[ -n ${SSH_CONNECTION-}${SSH_TTY-} ]]; then
        _zle_editor_copy_osc52 "$text"
        return
    fi

    if (( ${+commands[pbcopy]} )) && print -rn -- "$text" | command pbcopy; then
        return 0
    fi
    if [[ -n ${WAYLAND_DISPLAY-} ]] && (( ${+commands[wl-copy]} )) &&
       print -rn -- "$text" | command wl-copy --type 'text/plain;charset=utf-8'; then
        return 0
    fi
    if (( ${+commands[xclip]} )) &&
       print -rn -- "$text" | command xclip -selection clipboard -in; then
        return 0
    fi

    _zle_editor_copy_osc52 "$text"
}

_zle_editor_copy() {
    local text
    _zle_editor_region_text || return 0
    text=$REPLY
    CUTBUFFER=$text

    if ! _zle_editor_clipboard_copy "$text" 2>/dev/null; then
        zle -M 'No working clipboard backend (pbcopy, wl-copy, xclip, or OSC 52)'
        return 1
    fi
}

_zle_editor_cut() {
    _zle_editor_has_region || return 0
    _zle_editor_copy || return 1
    _zle_editor_delete_region
    _zle_editor_refresh_suggestion
}

# Register standalone widgets.
for _zle_editor_widget in \
    _zle_editor_select_left _zle_editor_select_right \
    _zle_editor_select_up _zle_editor_select_down \
    _zle_editor_select_word_left _zle_editor_select_word_right \
    _zle_editor_select_line_start _zle_editor_select_line_end \
    _zle_editor_select_buffer_start _zle_editor_select_buffer_end \
    _zle_editor_word_left _zle_editor_word_right \
    _zle_editor_select_all _zle_editor_move_left _zle_editor_move_right \
    _zle_editor_move_up _zle_editor_move_down \
    _zle_editor_move_word_left _zle_editor_move_word_right \
    _zle_editor_move_line_start _zle_editor_move_line_end \
    _zle_editor_move_buffer_start _zle_editor_move_buffer_end \
    _zle_editor_delete_word_left _zle_editor_delete_word_right \
    _zle_editor_delete_line_start _zle_editor_delete_line_end \
    _zle_editor_insert_newline \
    _zle_editor_copy _zle_editor_cut _zle_editor_undo _zle_editor_redo; do
    zle -N "$_zle_editor_widget"
done
unset _zle_editor_widget

# A public widget name lets zsh-autosuggestions wrap the custom word motion as
# a partial accept action. Its underscore-prefixed ignore rule would skip the
# implementation widget above.
zle -N editor-word-right _zle_editor_move_word_right
if (( ${+parameters[ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS]} )); then
    ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS+=( editor-word-right )
fi
zle -N editor-line-end _zle_editor_move_line_end
if (( ${+parameters[ZSH_AUTOSUGGEST_ACCEPT_WIDGETS]} )); then
    ZSH_AUTOSUGGEST_ACCEPT_WIDGETS+=( editor-line-end )
fi
zle -N editor-up-or-history _zle_editor_up_or_history
zle -N editor-down-or-history _zle_editor_down_or_history
if (( ${+parameters[ZSH_AUTOSUGGEST_CLEAR_WIDGETS]} )); then
    ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=( editor-up-or-history editor-down-or-history )
fi
if (( ${+parameters[ZSH_AUTOSUGGEST_IGNORE_WIDGETS]} )); then
    ZSH_AUTOSUGGEST_IGNORE_WIDGETS+=( autopair-delete-word )
fi

# Preserve and wrap the current canonical insertion/deletion widgets.
zle -A self-insert _zle_editor_saved_self_insert
zle -A quoted-insert _zle_editor_saved_quoted_insert
zle -A yank _zle_editor_saved_yank
zle -A backward-delete-char _zle_editor_saved_backward_delete_char
zle -A delete-char _zle_editor_saved_delete_char
zle -N self-insert _zle_editor_self_insert
zle -N quoted-insert _zle_editor_quoted_insert
zle -N yank _zle_editor_yank
zle -N backward-delete-char _zle_editor_backward_delete_char
zle -N delete-char _zle_editor_delete_char

# Preserve optional autopair widgets exactly when no region is active.
if (( ${+widgets[autopair-insert]} )); then
    zle -A autopair-insert _zle_editor_saved_autopair_insert
    zle -N autopair-insert _zle_editor_autopair_insert
fi
if (( ${+widgets[autopair-close]} )); then
    zle -A autopair-close _zle_editor_saved_autopair_close
    zle -N autopair-close _zle_editor_autopair_close
fi
if (( ${+widgets[autopair-delete]} )); then
    zle -A autopair-delete _zle_editor_saved_autopair_delete
    zle -N autopair-delete _zle_editor_autopair_delete
fi
if (( ${+widgets[autopair-delete-word]} )); then
    zle -A autopair-delete-word _zle_editor_saved_autopair_delete_word
    zle -N autopair-delete-word _zle_editor_autopair_delete_word
fi

_zle_editor_bind() {
    local keymap=$1
    local sequence=$2
    local widget=$3
    bindkey -M "$keymap" "$sequence" "$widget"
}

for _zle_editor_keymap in emacs viins; do
    # Character and vertical selection.
    _zle_editor_bind $_zle_editor_keymap $'\e[1;2D' _zle_editor_select_left
    _zle_editor_bind $_zle_editor_keymap $'\e[1;2C' _zle_editor_select_right
    _zle_editor_bind $_zle_editor_keymap $'\e[1;2A' _zle_editor_select_up
    _zle_editor_bind $_zle_editor_keymap $'\e[1;2B' _zle_editor_select_down

    # Option movement and Shift+Option selection by word.
    _zle_editor_bind $_zle_editor_keymap $'\e[1;3D' _zle_editor_move_word_left
    _zle_editor_bind $_zle_editor_keymap $'\e[1;3C' editor-word-right
    _zle_editor_bind $_zle_editor_keymap $'\eb' _zle_editor_move_word_left
    _zle_editor_bind $_zle_editor_keymap $'\ef' editor-word-right
    _zle_editor_bind $_zle_editor_keymap $'\e[1;4D' _zle_editor_select_word_left
    _zle_editor_bind $_zle_editor_keymap $'\e[1;4C' _zle_editor_select_word_right
    _zle_editor_bind $_zle_editor_keymap $'\e[1;3A' _zle_editor_move_up
    _zle_editor_bind $_zle_editor_keymap $'\e[1;3B' _zle_editor_move_down
    _zle_editor_bind $_zle_editor_keymap $'\e[1;4A' _zle_editor_select_up
    _zle_editor_bind $_zle_editor_keymap $'\e[1;4B' _zle_editor_select_down

    # Command movement and Shift+Command selection.
    _zle_editor_bind $_zle_editor_keymap '^A' _zle_editor_move_line_start
    _zle_editor_bind $_zle_editor_keymap '^E' editor-line-end
    _zle_editor_bind $_zle_editor_keymap $'\e[1;9D' _zle_editor_move_line_start
    _zle_editor_bind $_zle_editor_keymap $'\e[1;9C' editor-line-end
    _zle_editor_bind $_zle_editor_keymap $'\e<' _zle_editor_move_buffer_start
    _zle_editor_bind $_zle_editor_keymap $'\e>' _zle_editor_move_buffer_end
    _zle_editor_bind $_zle_editor_keymap $'\e[1;9A' _zle_editor_move_buffer_start
    _zle_editor_bind $_zle_editor_keymap $'\e[1;9B' _zle_editor_move_buffer_end
    _zle_editor_bind $_zle_editor_keymap $'\e[1;10D' _zle_editor_select_line_start
    _zle_editor_bind $_zle_editor_keymap $'\e[1;10C' _zle_editor_select_line_end
    _zle_editor_bind $_zle_editor_keymap $'\e[1;10A' _zle_editor_select_buffer_start
    _zle_editor_bind $_zle_editor_keymap $'\e[1;10B' _zle_editor_select_buffer_end

    # Plain horizontal movement collapses an active region correctly.
    _zle_editor_bind $_zle_editor_keymap $'\e[D' _zle_editor_move_left
    _zle_editor_bind $_zle_editor_keymap $'\e[C' _zle_editor_move_right
    _zle_editor_bind $_zle_editor_keymap $'\eOD' _zle_editor_move_left
    _zle_editor_bind $_zle_editor_keymap $'\eOC' _zle_editor_move_right
    _zle_editor_bind $_zle_editor_keymap $'\e[A' editor-up-or-history
    _zle_editor_bind $_zle_editor_keymap $'\e[B' editor-down-or-history
    _zle_editor_bind $_zle_editor_keymap $'\eOA' editor-up-or-history
    _zle_editor_bind $_zle_editor_keymap $'\eOB' editor-down-or-history

    # Home/End selection.
    _zle_editor_bind $_zle_editor_keymap $'\e[1;2H' _zle_editor_select_line_start
    _zle_editor_bind $_zle_editor_keymap $'\e[1;2F' _zle_editor_select_line_end

    # Character, word, and line deletion.
    _zle_editor_bind $_zle_editor_keymap '^U' _zle_editor_delete_line_start
    _zle_editor_bind $_zle_editor_keymap '^K' _zle_editor_delete_line_end
    _zle_editor_bind $_zle_editor_keymap '^J' _zle_editor_insert_newline
    _zle_editor_bind $_zle_editor_keymap $'\e[3~' delete-char
    _zle_editor_bind $_zle_editor_keymap $'\e\x7f' _zle_editor_delete_word_left
    _zle_editor_bind $_zle_editor_keymap $'\ed' _zle_editor_delete_word_right
    _zle_editor_bind $_zle_editor_keymap $'\e[3;5~' _zle_editor_delete_word_right

    if (( ${+widgets[autopair-delete]} )); then
        _zle_editor_bind $_zle_editor_keymap '^?' autopair-delete
        _zle_editor_bind $_zle_editor_keymap '^H' autopair-delete
    else
        _zle_editor_bind $_zle_editor_keymap '^?' _zle_editor_backward_delete_char
        _zle_editor_bind $_zle_editor_keymap '^H' _zle_editor_backward_delete_char
    fi
    if (( ${+widgets[autopair-delete-word]} )); then
        _zle_editor_bind $_zle_editor_keymap '^W' autopair-delete-word
    else
        _zle_editor_bind $_zle_editor_keymap '^W' _zle_editor_delete_word_left
    fi

    # Private terminal transport namespace.
    _zle_editor_bind $_zle_editor_keymap $'\e[97;9u' _zle_editor_select_all
    _zle_editor_bind $_zle_editor_keymap $'\e[99;9u' _zle_editor_copy
    _zle_editor_bind $_zle_editor_keymap $'\e[120;9u' _zle_editor_cut
    _zle_editor_bind $_zle_editor_keymap $'\e[122;9u' _zle_editor_undo
    _zle_editor_bind $_zle_editor_keymap $'\e[122;10u' _zle_editor_redo
    _zle_editor_bind $_zle_editor_keymap $'\e[99~' _zle_editor_copy
    _zle_editor_bind $_zle_editor_keymap $'\e[99;1~' _zle_editor_select_all
    _zle_editor_bind $_zle_editor_keymap $'\e[99;2~' _zle_editor_cut
    _zle_editor_bind $_zle_editor_keymap $'\e[99;3~' _zle_editor_undo
    _zle_editor_bind $_zle_editor_keymap $'\e[99;4~' _zle_editor_redo
    # Legacy private transport remains accepted by older exported profiles.
    _zle_editor_bind $_zle_editor_keymap $'\e[99;5~' _zle_editor_delete_line_start
    _zle_editor_bind $_zle_editor_keymap $'\e[99;6~' _zle_editor_delete_line_end
    _zle_editor_bind $_zle_editor_keymap $'\e[99;7~' _zle_editor_delete_word_left
    _zle_editor_bind $_zle_editor_keymap $'\e[99;8~' _zle_editor_insert_newline
    _zle_editor_bind $_zle_editor_keymap $'\e[13;5u' _zle_editor_insert_newline
done
unset _zle_editor_keymap
