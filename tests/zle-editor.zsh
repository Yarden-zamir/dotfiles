#!/usr/bin/env zsh
# Integration tests for zshrc/post-init/zle-editor.zsh.
# Uses zsh/zpty to exercise real ZLE widgets without depending on a terminal emulator.

emulate -L zsh
setopt errexit nounset pipefail

zmodload zsh/zpty

typeset -gr ROOT=${0:A:h:h}
typeset -gr EDITOR_FILE=$ROOT/zshrc/post-init/zle-editor.zsh
typeset -gr AUTOPAIR_FILE=$HOME/Github/zsh-autopair/autopair.zsh
typeset -gr HISTORY_SEARCH_FILE=$HOME/Github/zsh-history-substring-search/zsh-history-substring-search.zsh
typeset -gr AUTOSUGGEST_FILE=$HOME/Github/zsh-autosuggestions/zsh-autosuggestions.zsh

typeset -gi tests_run=0
typeset -gi tests_failed=0
typeset -gi sync_id=0

cleanup() {
    zpty -d editor 2>/dev/null || true
}
trap cleanup EXIT INT TERM

fail() {
    print -ru2 -- "not ok - $1"
    print -ru2 -- "  expected: $2"
    print -ru2 -- "  output:   ${(V)3}"
    (( ++tests_failed ))
}

pass() {
    print -r -- "ok - $1"
}

read_prompt() {
    local output
    zpty -r editor output '*READY> '
    REPLY=$output
}

send_command() {
    local marker="ZLE_EDITOR_SYNC_$(( ++sync_id ))"
    zpty -w -n editor $'\e[200~'"$1; print -r -- $marker"$'\e[201~\r'
    local output
    zpty -r editor output "*$marker*READY> "
    REPLY=$output
}

assert_output() {
    local name=$1
    local expected=$2
    local output=${3//$'\r'/}
    (( ++tests_run ))

    if [[ $output == *$expected* ]]; then
        pass "$name"
    else
        fail "$name" "$expected" "$output"
    fi
}

edit_case() {
    local name=$1
    local input=$2
    local keys=$3
    local expected=$4

    zpty -w -n editor "$input$keys"$'\e[98~'
    local output
    zpty -r editor output '*RESULT:*READY> '
    assert_output "$name" "$expected" "$output"
}

suggestion_case() {
    local name=$1
    local input=$2
    local keys=$3
    local expected=$4

    zpty -w -n editor "$input$keys"$'\e[94~'
    local output
    zpty -r editor output '*SUGGESTION:*READY> '
    assert_output "$name" "$expected" "$output"
}

[[ -r $EDITOR_FILE ]] || {
    print -ru2 -- "Missing editor file: $EDITOR_FILE"
    exit 1
}
[[ -r $AUTOPAIR_FILE ]] || {
    print -ru2 -- "Missing autopair dependency: $AUTOPAIR_FILE"
    exit 1
}
[[ -r $HISTORY_SEARCH_FILE ]] || {
    print -ru2 -- "Missing history-search dependency: $HISTORY_SEARCH_FILE"
    exit 1
}
[[ -r $AUTOSUGGEST_FILE ]] || {
    print -ru2 -- "Missing autosuggestions dependency: $AUTOSUGGEST_FILE"
    exit 1
}

zpty -b editor zsh -f
typeset initial_prompt
zpty -r editor initial_prompt '*% '

send_command "PS1='READY> '; RPROMPT=''; setopt HIST_IGNORE_SPACE; source ${(q)AUTOPAIR_FILE}; source ${(q)HISTORY_SEARCH_FILE}; source ${(q)AUTOSUGGEST_FILE}; _test_base_self_insert() { typeset -g TEST_BASE_INSERT_PRESERVED=yes; zle .self-insert; }; zle -N self-insert _test_base_self_insert; bindkey '^[[A' history-substring-search-up; bindkey '^[[B' history-substring-search-down; source ${(q)EDITOR_FILE}; _zsh_autosuggest_bind_widgets"

# Replace the system clipboard backend with an in-memory test double.
send_command '_zle_editor_clipboard_copy() { typeset -g TEST_CLIPBOARD=$1; }'

# Turn the current edit state into a safe print command and execute it.
send_command 'function _test_report { local output="RESULT:<${BUFFER}>:${CURSOR}:${REGION_ACTIVE}"; BUFFER="print -r -- ${(q)output}"; CURSOR=${#BUFFER}; zle accept-line }; function _test_report_suggestion { local output="SUGGESTION:<${BUFFER}>:<${POSTDISPLAY}>"; BUFFER="print -r -- ${(q)output}"; CURSOR=${#BUFFER}; zle accept-line }; function _test_newline { LBUFFER+=$'"'"'\n'"'"' }; function _test_crlf { LBUFFER+=$'"'"'\r\n'"'"' }; function _test_suggestion { POSTDISPLAY=" bar" }; function _test_autosuggest_fetch { POSTDISPLAY="fresh:${BUFFER}" }; zle -N _test_report; zle -N _test_report_suggestion; zle -N _test_newline; zle -N _test_crlf; zle -N _test_suggestion; zle -N autosuggest-fetch _test_autosuggest_fetch; bindkey "^[[98~" _test_report; bindkey "^[[97~" _test_newline; bindkey "^[[96~" _test_suggestion; bindkey "^[[95~" _test_crlf; bindkey "^[[94~" _test_report_suggestion'

typeset -gr SHIFT_LEFT=$'\e[1;2D'
typeset -gr SHIFT_RIGHT=$'\e[1;2C'
typeset -gr LEFT=$'\e[D'
typeset -gr RIGHT=$'\e[C'
typeset -gr OPTION_RIGHT=$'\e[1;3C'
typeset -gr SHIFT_OPTION_LEFT=$'\e[1;4D'
typeset -gr BUFFER_START=$'\e<'
typeset -gr BUFFER_END=$'\e>'
typeset -gr LINE_START=$'\e[1;9D'
typeset -gr LINE_END=$'\e[1;9C'
typeset -gr SELECT_ALL=$'\e[97;9u'
typeset -gr COPY=$'\e[99;9u'
typeset -gr CUT=$'\e[120;9u'
typeset -gr UNDO=$'\e[122;9u'
typeset -gr REDO=$'\e[122;10u'
typeset -gr DELETE_LINE_START=$'\e[99;5~'
typeset -gr DELETE_LINE_END=$'\x0b'
typeset -gr DELETE_WORD_LEFT=$'\x17'
typeset -gr DELETE_WORD_RIGHT=$'\e[3;5~'
typeset -gr DELETE=$'\e[3~'
typeset -gr CTRL_ENTER=$'\e[13;5u'
typeset -gr REPORT=$'\e[98~'
typeset -gr INSERT_NEWLINE=$'\e[97~'
typeset -gr SET_SUGGESTION=$'\e[96~'
typeset -gr INSERT_CRLF=$'\e[95~'
typeset -gr OPTION_DELETE_WORD_LEFT=$'\e\x7f'

edit_case \
    'typing replaces selection' \
    'abcdef' \
    "$SHIFT_LEFT$SHIFT_LEFT${SHIFT_LEFT}X" \
    'RESULT:<abcX>:4:0'

edit_case \
    'Backspace deletes selection' \
    'abcdef' \
    "$SHIFT_LEFT$SHIFT_LEFT$SHIFT_LEFT"$'\x7f' \
    'RESULT:<abc>:3:0'

edit_case \
    'Delete deletes selection' \
    'abcdef' \
    "$SHIFT_LEFT$SHIFT_LEFT$SHIFT_LEFT$DELETE" \
    'RESULT:<abc>:3:0'

edit_case \
    'Left collapses to selection start' \
    'abcdef' \
    "$SHIFT_LEFT$SHIFT_LEFT$SHIFT_LEFT$LEFT" \
    'RESULT:<abcdef>:3:0'

edit_case \
    'Right collapses to selection end' \
    'abcdef' \
    "$SHIFT_LEFT$SHIFT_LEFT$SHIFT_LEFT$RIGHT" \
    'RESULT:<abcdef>:6:0'

edit_case \
    'repeated Command-Up stays at buffer start' \
    'abcdef' \
    "$BUFFER_START$BUFFER_START" \
    'RESULT:<abcdef>:0:0'

edit_case \
    'repeated Command-Down stays at buffer end' \
    'abcdef' \
    "$BUFFER_END$BUFFER_END" \
    'RESULT:<abcdef>:6:0'

edit_case \
    'Command-Left moves to current line start' \
    "one${INSERT_NEWLINE}two" \
    "$LEFT$LINE_START" \
    $'RESULT:<one\ntwo>:4:0'

edit_case \
    'Command-Right moves to current line end' \
    "one${INSERT_NEWLINE}two" \
    "$BUFFER_START$LINE_END" \
    $'RESULT:<one\ntwo>:3:0'

edit_case \
    'Option-Right partially accepts autosuggestion' \
    'foo' \
    "$SET_SUGGESTION$OPTION_RIGHT" \
    'RESULT:<foo bar>:7:0'

edit_case \
    'Shift-Right does not accept autosuggestion' \
    'foo' \
    "$SET_SUGGESTION$SHIFT_RIGHT" \
    'RESULT:<foo>:3:1'

edit_case \
    'Command-Right accepts autosuggestion' \
    'foo' \
    "$SET_SUGGESTION"$'\x05' \
    'RESULT:<foo bar>:7:0'

edit_case \
    'Shift-Option-Left selects by word' \
    'foo bar' \
    "$SHIFT_OPTION_LEFT"'X' \
    'RESULT:<foo X>:5:0'

edit_case \
    'Command-A replaces a multiline buffer' \
    "one${INSERT_NEWLINE}two" \
    "${SELECT_ALL}X" \
    'RESULT:<X>:1:0'

edit_case \
    'Ctrl-Enter inserts a newline' \
    'onetwo' \
    "$LEFT$LEFT$LEFT$CTRL_ENTER" \
    $'RESULT:<one\ntwo>:4:0'

edit_case \
    'Ctrl-Enter replaces selection with a newline' \
    'abcdef' \
    "$SHIFT_LEFT$SHIFT_LEFT$SHIFT_LEFT$CTRL_ENTER" \
    $'RESULT:<abc\n>:4:0'

edit_case \
    'autopair survives insertion wrapper' \
    '' \
    '(' \
    'RESULT:<()>:1:0'

edit_case \
    'bracketed paste replaces selection' \
    'abcdef' \
    "$SHIFT_LEFT$SHIFT_LEFT$SHIFT_LEFT"$'\e[200~XYZ\e[201~' \
    'RESULT:<abcXYZ>:6:0'

edit_case \
    'Command-Backspace deletes to line start' \
    "one${INSERT_NEWLINE}two" \
    "$LEFT$DELETE_LINE_START" \
    $'RESULT:<one\no>:4:0'

edit_case \
    'Ctrl-U deletes to line start' \
    "one${INSERT_NEWLINE}two" \
    "$LEFT"$'\x15' \
    $'RESULT:<one\no>:4:0'

edit_case \
    'Command-Delete deletes to line end' \
    "one${INSERT_NEWLINE}two" \
    "$LEFT$LEFT$DELETE_LINE_END" \
    $'RESULT:<one\nt>:5:0'

edit_case \
    'Command-Delete joins a CRLF boundary' \
    "one${INSERT_CRLF}two" \
    "$BUFFER_START$RIGHT$RIGHT$RIGHT$DELETE_LINE_END" \
    'RESULT:<onetwo>:3:0'

edit_case \
    'Ctrl-Backspace deletes the previous word' \
    'foo-bar baz' \
    "$DELETE_WORD_LEFT" \
    'RESULT:<foo-bar >:8:0'

suggestion_case \
    'word deletion refetches autosuggestion' \
    'foo bar' \
    "$SET_SUGGESTION$OPTION_DELETE_WORD_LEFT" \
    'SUGGESTION:<foo >:<fresh:foo >'

suggestion_case \
    'Ctrl-Backspace refetches autosuggestion' \
    'foo bar' \
    "$SET_SUGGESTION$DELETE_WORD_LEFT" \
    'SUGGESTION:<foo >:<fresh:foo >'

edit_case \
    'Ctrl-Delete deletes the next word' \
    'foo-bar baz' \
    $'\x01'"$DELETE_WORD_RIGHT" \
    'RESULT:<-bar baz>:0:0'

edit_case \
    'copy preserves buffer and selection' \
    'abcdef' \
    "$SHIFT_LEFT$SHIFT_LEFT$SHIFT_LEFT$COPY" \
    'RESULT:<abcdef>:3:1'

send_command 'print -r -- "CLIPBOARD:<${TEST_CLIPBOARD-}>"'
assert_output 'copy writes exact selected text' 'CLIPBOARD:<def>' "$REPLY"

edit_case \
    'cut copies and deletes selection' \
    'abcdef' \
    "$SHIFT_LEFT$SHIFT_LEFT$SHIFT_LEFT$CUT" \
    'RESULT:<abc>:3:0'

send_command 'print -r -- "CLIPBOARD:<${TEST_CLIPBOARD-}>"'
assert_output 'cut writes exact selected text' 'CLIPBOARD:<def>' "$REPLY"

# Undo and redo are checked in one edit session before the report widget accepts it.
edit_case \
    'Command-Z undoes region replacement' \
    'abc' \
    "$SHIFT_LEFT"'X'"$UNDO" \
    'RESULT:<abc>:2:0'

edit_case \
    'Command-Shift-Z redoes region replacement' \
    'abc' \
    "$SHIFT_LEFT"'X'"$UNDO$REDO" \
    'RESULT:<abX>:3:0'

edit_case \
    'Up moves within a multiline buffer before history' \
    "one${INSERT_NEWLINE}two" \
    "$LEFT"$'\e[A' \
    $'RESULT:<one\ntwo>:2:0'

edit_case \
    'Down moves within a multiline history buffer first' \
    "one${INSERT_NEWLINE}two" \
    "$BUFFER_START$RIGHT$RIGHT"$'\e[B' \
    $'RESULT:<one\ntwo>:6:0'

typeset history_entry=$'one\ntwo'
send_command " print -s -- ${(q)history_entry}"
edit_case \
    'history recall starts on the first line' \
    '' \
    $'\e[A' \
    $'RESULT:<one\ntwo>:0:0'

history_entry=$'git\nstatus'
send_command " print -s -- ${(q)history_entry}"
edit_case \
    'history search preserves the query column' \
    'git' \
    $'\e[A' \
    $'RESULT:<git\nstatus>:3:0'

history_entry=$'echo one\necho two'
send_command " print -s -- ${(q)history_entry}"
edit_case \
    'typing after history recall edits first-line position' \
    '' \
    $'\e[A''X' \
    $'RESULT:<Xecho one\necho two>:1:0'

history_entry=$'backspace\nstays'
send_command " print -s -- ${(q)history_entry}"
edit_case \
    'Backspace after history recall stays at first-line position' \
    '' \
    $'\e[A\x7f' \
    $'RESULT:<backspace\nstays>:0:0'

history_entry=$'alpha\nbeta'
send_command " print -s -- ${(q)history_entry}"
edit_case \
    'movement after history recall keeps explicit edit position' \
    '' \
    $'\e[A'"$RIGHT"'X' \
    $'RESULT:<aXlpha\nbeta>:2:0'

send_command 'print -r -- "BASE_INSERT:<${TEST_BASE_INSERT_PRESERVED-}>"'
assert_output 'pre-existing self-insert wrapper is preserved' 'BASE_INSERT:<yes>' "$REPLY"

cleanup
trap - EXIT INT TERM

# Verify the documented no-plugin fallback in a separate clean ZLE process.
zpty -b plain zsh -f
typeset plain_output
zpty -r plain plain_output '*% '
zpty -w -n plain $'\e[200~'"PS1='PLAIN> '; RPROMPT=''; setopt HIST_IGNORE_SPACE; source ${(q)EDITOR_FILE}; print -r -- PLAIN_READY"$'\e[201~\r'
zpty -r plain plain_output '*PLAIN_READY*PLAIN> '
zpty -w -n plain $'\e[200~''function _plain_report { local output="PLAIN_RESULT:<${BUFFER}>:${CURSOR}:${REGION_ACTIVE}"; BUFFER="print -r -- ${(q)output}"; CURSOR=${#BUFFER}; zle accept-line }; zle -N _plain_report; bindkey "^[[98~" _plain_report; print -r -- PLAIN_REPORT_READY'$'\e[201~\r'
zpty -r plain plain_output '*PLAIN_REPORT_READY*PLAIN> '
zpty -w -n plain 'foo bar'$'\x17\e[98~'
zpty -r plain plain_output '*PLAIN_RESULT:*PLAIN> '
assert_output \
    'Ctrl-W deletes by editor word without autopair' \
    'PLAIN_RESULT:<foo >:4:0' \
    "$plain_output"

typeset plain_history=$'plain\nhistory'
zpty -w -n plain $'\e[200~'" print -s -- ${(q)plain_history}; print -r -- PLAIN_HISTORY_READY"$'\e[201~\r'
zpty -r plain plain_output '*PLAIN_HISTORY_READY*PLAIN> '
zpty -w -n plain $'\e[A\e[98~'
zpty -r plain plain_output '*PLAIN_RESULT:*PLAIN> '
assert_output \
    'Up falls back to native history without plugin' \
    $'PLAIN_RESULT:<plain\nhistory>:0:0' \
    "$plain_output"

plain_history=$'newer\nentry'
zpty -w -n plain $'\e[200~'" print -s -- ${(q)plain_history}; print -r -- PLAIN_DOWN_READY"$'\e[201~\r'
zpty -r plain plain_output '*PLAIN_DOWN_READY*PLAIN> '
zpty -w -n plain $'\e[A\e>\e[B\e[98~'
zpty -r plain plain_output '*PLAIN_RESULT:*PLAIN> '
assert_output \
    'Down falls back to native history without plugin' \
    'PLAIN_RESULT:<>:0:0' \
    "$plain_output"
zpty -d plain

typeset osc52_output
osc52_output=$(TERM=dumb ZLE_EDITOR_TEST_FILE=$EDITOR_FILE zsh -fic 'source "$ZLE_EDITOR_TEST_FILE"; _zle_editor_copy_osc52 $'"'"'a\nb'"'"'')
assert_output 'OSC 52 fallback encodes multiline text' $'\e]52;c;YQpi\e\\' "$osc52_output"

# Validate integration with the complete configured shell.
typeset configured_bindings
configured_bindings=$(zsh -lic 'bindkey -M emacs "^I"; bindkey -M emacs "^D"; bindkey -M emacs "^J"; bindkey -M emacs "^K"; bindkey -M emacs "^@"; bindkey -M emacs "^L"; bindkey -M emacs "^N"; bindkey -M emacs "^S"; bindkey -M emacs $'"'"'\e[97;9u'"'"'; zle -l -L self-insert autopair-delete' 2>/dev/null)
typeset configured_open_widgets
configured_open_widgets=$(zsh -lic 'print -r -- ${+widgets[open-with]}:${+widgets[open-with-code]}' 2>/dev/null)
assert_output 'Tab remains fzf-tab completion' 'fzf-tab-complete' "$configured_bindings"
assert_output 'Ctrl-D remains completion-aware' 'delete-char-or-list' "$configured_bindings"
assert_output 'configured shell loads private ZLE bindings' '_zle_editor_select_all' "$configured_bindings"
assert_output 'configured shell wraps normal insertion' '_zle_editor_self_insert' "$configured_bindings"
assert_output 'configured shell preserves autopair deletion' '_zle_editor_autopair_delete' "$configured_bindings"
assert_output 'physical Ctrl-K uses line-end deletion' '_zle_editor_delete_line_end' "$configured_bindings"
assert_output 'Ctrl-Space opens Navgator' 'navigate' "$configured_bindings"
assert_output 'Ctrl-N opens Navgator create' 'navgator-create' "$configured_bindings"
assert_output 'Ctrl-S opens Sessiongator' 'ai-sessions' "$configured_bindings"
assert_output 'VS Code opener widget is removed' '1:0' "$configured_open_widgets"

print -r -- "$(( tests_run - tests_failed ))/$tests_run tests passed"
(( tests_failed == 0 ))
