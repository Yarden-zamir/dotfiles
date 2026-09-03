# Kitty keyboard protocol for ZLE. Replaces the iTerm profile transports
# (bin/iterm-zle-profile-sync) for Ghostty and herdr panes.
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

[[ -n ${HERDR_PANE_ID-} || ${TERM_PROGRAM-} == ghostty ]] || return 0

_zle_kitty_push() { print -n '\e[>1u' > /dev/tty }
_zle_kitty_pop()  { print -n '\e[<u'  > /dev/tty }
_zle_kitty_interrupt() { zle send-break }
zle -N _zle_kitty_interrupt

autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-init _zle_kitty_push
add-zle-hook-widget line-finish _zle_kitty_pop

# Mirror a legacy sequence's widget onto a CSI-u sequence in one keymap.
_zle_kitty_mirror() {
    local keymap=$1 legacy=$2 csiu=$3
    local listing widget
    listing=$(bindkey -M "$keymap" "$legacy") || return 0
    widget=${${(z)listing}[2]}
    [[ -z $widget || $widget == undefined-key ]] && return 0
    bindkey -M "$keymap" "$csiu" "$widget"
}

local _zk_keymap _zk_code _zk_char
for _zk_keymap in emacs viins; do
    # ctrl+letter: legacy control byte -> CSI-u ";5u".
    for _zk_code in {97..122}; do
        _zk_char=${(#):-$(( _zk_code - 96 ))}
        _zle_kitty_mirror "$_zk_keymap" "$_zk_char" $'\e['"${_zk_code};5u"
    done
    # ctrl+space (^@) and ctrl+] carry navgator and jq-complete.
    _zle_kitty_mirror "$_zk_keymap" $'\C-@' $'\e[32;5u'
    _zle_kitty_mirror "$_zk_keymap" $'\C-]' $'\e[93;5u'
    # alt+letter and alt+space: legacy ESC prefix -> CSI-u ";3u".
    for _zk_code in {97..122} 32 60 62; do
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
unset _zk_keymap _zk_code _zk_char

# Widgets that spawn a TUI (fzf, navgator, sessiongator, harness picker)
# run while the flags are still pushed, which feeds those programs CSI-u
# input they do not expect. Pop around the spawn, push again after.
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
    ask_atuin_ai ask_opencode; do
    (( ${+widgets[$_zk_widget]} )) || continue
    zle -A "$_zk_widget" "_zk_orig_$_zk_widget"
    zle -N "$_zk_widget" _zle_kitty_tui_widget
done
unset _zk_widget
