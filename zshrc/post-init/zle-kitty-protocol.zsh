# Kitty keyboard protocol for ZLE. Provides the key transports for Ghostty
# and herdr panes; no terminal profile is needed.
#
# ZLE pushes the disambiguate flag while it edits and pops it before a
# command runs. Terminals and herdr then deliver Command and modified keys
# as CSI-u sequences instead of dropping them. Remote shells that load
# these dotfiles negotiate the same way through ssh, so no per-host
# profile switching is needed.
#
# Under disambiguate, ctrl+letter arrives as CSI-u instead of a control
# byte, so this file mirrors every existing ctrl and alt binding onto its
# CSI-u sequence. It must load after bindings.zsh and zle-editor.zsh.

# T3 Code terminals run the Ghostty engine and set T3CODE_PROJECT_ROOT.
[[ -n ${HERDR_PANE_ID-} || ${TERM_PROGRAM-} == ghostty || -n ${T3CODE_PROJECT_ROOT-} ]] || return 0

_zle_kitty_push() { print -n '\e[>1u' > /dev/tty }
_zle_kitty_pop()  { print -n '\e[<u'  > /dev/tty }
_zle_kitty_interrupt() { zle send-break }
zle -N _zle_kitty_interrupt

autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-init _zle_kitty_push
add-zle-hook-widget line-finish _zle_kitty_pop

# Legacy bindings of the keymap in work, keyed by caret notation (^[b).
# One dump per keymap: a subshell per lookup costs 0.2 s at startup.
typeset -gA _zk_bound
_zle_kitty_load_bound() {
    local line
    local -a words
    _zk_bound=()
    for line in ${(f)"$(bindkey -M "$1" -L)"}; do
        words=(${(z)line})
        # Ranges (bindkey -R) cover self-insert only; skip them.
        [[ ${words[2]} == -R ]] && continue
        _zk_bound[${(Q)words[-2]}]=${words[-1]}
    done
}

# Caret notation as bindkey -L prints it: control bytes as ^X, DEL as ^?.
# (V) is not enough: it prints tab and newline as \t and \n.
_zle_kitty_caret() {
    local out= ch
    local -i code
    for ch in "${(@s::)1}"; do
        code=$(( #ch ))
        if (( code < 32 )); then
            out+="^${(#):-$(( code + 64 ))}"
        elif (( code == 127 )); then
            out+='^?'
        else
            out+=$ch
        fi
    done
    REPLY=$out
}

# Mirror a legacy sequence's widget onto a CSI-u sequence in one keymap.
_zle_kitty_mirror() {
    local keymap=$1 legacy=$2 csiu=$3
    local REPLY
    _zle_kitty_caret "$legacy"
    local widget=${_zk_bound[$REPLY]-}
    [[ -z $widget || $widget == undefined-key ]] && return 0
    bindkey -M "$keymap" "$csiu" "$widget"
}

# An unbound CSI-u key leaks its tail into the line (esc typed "u",
# ctrl+/ typed "7;5u"). Bind every modified printable key and esc to a
# no-op first; the mirrors below then replace the keys that have a widget.
# Limit: super (;9u ;10u) is not covered, because zle-editor.zsh binds
# some of those before this file runs; revisit if a cmd+key leaks text.
_zle_kitty_ignore() { : }
zle -N _zle_kitty_ignore

local _zk_keymap _zk_code _zk_char _zk_mod
for _zk_keymap in emacs viins; do
    _zle_kitty_load_bound "$_zk_keymap"
    bindkey -M "$_zk_keymap" $'\e[27u' _zle_kitty_ignore
    for _zk_mod in {2..8}; do
        bindkey -M "$_zk_keymap" $'\e['"27;${_zk_mod}u" _zle_kitty_ignore
        # Mod 2 (shift alone) sends plain text for printable keys.
        (( _zk_mod == 2 )) && continue
        for _zk_code in {32..126}; do
            bindkey -M "$_zk_keymap" $'\e['"${_zk_code};${_zk_mod}u" _zle_kitty_ignore
        done
    done
    # ctrl+/ is the legacy ^_ (undo).
    _zle_kitty_mirror "$_zk_keymap" $'\C-_' $'\e[47;5u'
    # ctrl+letter: legacy control byte -> CSI-u ";5u".
    for _zk_code in {97..122}; do
        _zk_char=${(#):-$(( _zk_code - 96 ))}
        _zle_kitty_mirror "$_zk_keymap" "$_zk_char" $'\e['"${_zk_code};5u"
    done
    # ctrl+space (^@) and ctrl+] carry navgator and jq-complete.
    _zle_kitty_mirror "$_zk_keymap" $'\C-@' $'\e[32;5u'
    _zle_kitty_mirror "$_zk_keymap" $'\C-]' $'\e[93;5u'
    # alt+printable key: legacy ESC prefix -> CSI-u ";3u".
    for _zk_code in {32..126}; do
        _zk_char=${(#):-$_zk_code}
        _zle_kitty_mirror "$_zk_keymap" $'\e'"$_zk_char" $'\e['"${_zk_code};3u"
    done
    # Modified backspace has no legacy form herdr forwards with super.
    bindkey -M "$_zk_keymap" $'\e[127;9u' _zle_editor_delete_line_start
    _zle_kitty_mirror "$_zk_keymap" $'\C-w' $'\e[127;5u'
    # Shift+Enter arrives as kitty CSI-u; insert a newline like Ctrl+Enter.
    bindkey -M "$_zk_keymap" $'\e[13;2u' _zle_editor_insert_newline
    # Word deletion: herdr re-encodes alt+backspace as CSI-u and
    # alt+delete as xterm modified-delete.
    bindkey -M "$_zk_keymap" $'\e[127;3u' _zle_editor_delete_word_left
    bindkey -M "$_zk_keymap" $'\e[3;3~' _zle_editor_delete_word_right
    # Under disambiguate, ctrl+c arrives as CSI-u instead of the tty
    # interrupt byte, so the driver never raises SIGINT at the prompt.
    # Abort the line from ZLE instead. Commands are unaffected: the pop
    # at line-finish runs before they start.
    bindkey -M "$_zk_keymap" $'\e[99;5u' _zle_kitty_interrupt
done
unset _zk_keymap _zk_code _zk_char _zk_mod _zk_bound

# Widgets that spawn a TUI (fzf, fzf-tab, atuin, navgator, sessiongator,
# harness picker) run while the flags are still pushed, which feeds those
# programs CSI-u input they do not expect (fzf prints esc as text).
# Pop around the spawn, push again after. A new TUI widget must join
# this list.
_zle_kitty_tui_widget() {
    _zle_kitty_pop
    zle "_zk_orig_$WIDGET" -- "$@"
    local _zk_ret=$?
    _zle_kitty_push
    return $_zk_ret
}
local _zk_widget
for _zk_widget in navigate navgator-create ai-sessions jq-complete \
    fzf-cd-widget fzf-file-widget ripgrep_search open-harness \
    ask_atuin_ai ask_opencode fzf-tab-complete fzf-completion \
    fzf-history-widget fzf-file-or-folder-to-editor \
    atuin-search atuin-search-viins atuin-search-vicmd \
    atuin-up-search atuin-up-search-viins atuin-up-search-vicmd \
    git-branch git-history git-stage open-with navgator-create-new-project; do
    (( ${+widgets[$_zk_widget]} )) || continue
    zle -A "$_zk_widget" "_zk_orig_$_zk_widget"
    zle -N "$_zk_widget" _zle_kitty_tui_widget
done
unset _zk_widget
