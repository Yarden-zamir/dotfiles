if ! zle -la >/dev/null 2>&1; then
  return 0
fi

# ZLE helpers for Ghostty key sequences.
# - Movement clears selection.
# - Selection starts/extends the region.
# - Word navigation matches VS Code defaults.

# VS Code default word separators.
WORDCHARS=''
GT_VSCODE_WORD_SEPARATORS=$'`~!@#$%^&*()-=+[{]}\\|;:\'",.<>/?'
typeset -gA GT_VSCODE_WORD_SEPARATOR_MAP
if (( ${#GT_VSCODE_WORD_SEPARATOR_MAP} == 0 )); then
  local i
  for i in {1..${#GT_VSCODE_WORD_SEPARATORS}}; do
    GT_VSCODE_WORD_SEPARATOR_MAP[${GT_VSCODE_WORD_SEPARATORS[i]}]=1
  done
fi

# Word scan results (0-based indices into BUFFER).
_gt_word_start=0
_gt_word_end=0
_gt_word_type=''
_gt_word_next_class=''

# Scan the next token (word or separator run) starting at pos.
_gt_scan_next_word() {
  local buf=$1
  local pos=$2
  local len=${#buf}
  local word_type=''
  local word_start=0
  local i ch class

  for (( i=pos; i<len; i++ )); do
    ch=${buf[i+1]}
    if [[ $ch == [[:space:]] ]]; then
      if [[ -n $word_type ]]; then
        _gt_word_start=$word_start
        _gt_word_end=$i
        _gt_word_type=$word_type
        _gt_word_next_class='ws'
        return 0
      fi
      continue
    fi

    if (( ${+GT_VSCODE_WORD_SEPARATOR_MAP[$ch]} )); then
      class='sep'
    else
      class='reg'
    fi

    if [[ -z $word_type ]]; then
      word_type=$class
      word_start=$i
    elif [[ $word_type == 'reg' && $class == 'sep' ]]; then
      _gt_word_start=$word_start
      _gt_word_end=$i
      _gt_word_type='reg'
      _gt_word_next_class='sep'
      return 0
    elif [[ $word_type == 'sep' && $class == 'reg' ]]; then
      _gt_word_start=$word_start
      _gt_word_end=$i
      _gt_word_type='sep'
      _gt_word_next_class='reg'
      return 0
    fi
  done

  if [[ -n $word_type ]]; then
    _gt_word_start=$word_start
    _gt_word_end=$len
    _gt_word_type=$word_type
    _gt_word_next_class='ws'
    return 0
  fi

  return 1
}

# Scan the previous token (word or separator run) ending at pos.
_gt_scan_prev_word() {
  local buf=$1
  local pos=$2
  local word_type=''
  local word_end=0
  local i ch class

  for (( i=pos; i>=0; i-- )); do
    ch=${buf[i+1]}
    if [[ $ch == [[:space:]] ]]; then
      if [[ -n $word_type ]]; then
        _gt_word_start=$(( i + 1 ))
        _gt_word_end=$word_end
        _gt_word_type=$word_type
        _gt_word_next_class='ws'
        return 0
      fi
      continue
    fi

    if (( ${+GT_VSCODE_WORD_SEPARATOR_MAP[$ch]} )); then
      class='sep'
    else
      class='reg'
    fi

    if [[ -z $word_type ]]; then
      word_type=$class
      word_end=$(( i + 1 ))
    elif [[ $word_type == 'reg' && $class == 'sep' ]]; then
      _gt_word_start=$(( i + 1 ))
      _gt_word_end=$word_end
      _gt_word_type='reg'
      _gt_word_next_class='sep'
      return 0
    elif [[ $word_type == 'sep' && $class == 'reg' ]]; then
      _gt_word_start=$(( i + 1 ))
      _gt_word_end=$word_end
      _gt_word_type='sep'
      _gt_word_next_class='reg'
      return 0
    fi
  done

  if [[ -n $word_type ]]; then
    _gt_word_start=0
    _gt_word_end=$word_end
    _gt_word_type=$word_type
    _gt_word_next_class='ws'
    return 0
  fi

  return 1
}

# VS Code "word right": WordEnd + skip single separator before a word.
_gt_word_right_vscode() {
  local buf=$BUFFER
  local len=${#buf}
  local pos=$CURSOR

  if (( pos >= len )); then
    return 0
  fi

  if _gt_scan_next_word "$buf" $pos; then
    if [[ $_gt_word_type == 'sep' ]] && (( _gt_word_end - _gt_word_start == 1 )) && [[ $_gt_word_next_class == 'reg' ]]; then
      if ! _gt_scan_next_word "$buf" $_gt_word_end; then
        CURSOR=$len
        return 0
      fi
    fi
    local new_pos=$_gt_word_end
    if (( new_pos == pos )); then
      (( new_pos++ ))
    fi
    if (( new_pos > len )); then
      new_pos=$len
    fi
    CURSOR=$new_pos
  else
    CURSOR=$len
  fi
}

# VS Code "word left": WordStart.
_gt_word_left_vscode() {
  local buf=$BUFFER
  local pos=$CURSOR

  if (( pos == 0 )); then
    return 0
  fi

  if _gt_scan_prev_word "$buf" $(( pos - 1 )); then
    CURSOR=$_gt_word_start
  else
    CURSOR=0
  fi
}

# Region helpers.
_gt_region_begin() {
  if (( REGION_ACTIVE == 0 )); then
    zle set-mark-command
  fi
}

_gt_region_extend_with() {
  _gt_region_begin
  zle "$1"
}

_gt_region_clear() {
  if (( REGION_ACTIVE )); then
    zle deactivate-region
  fi
}

_gt_move_with_clear() {
  _gt_region_clear
  zle "$1"
}

# Selection wrappers.
_gt_select_left() { _gt_region_extend_with backward-char }
_gt_select_right() { _gt_region_extend_with forward-char }
_gt_select_up() { _gt_region_extend_with up-line }
_gt_select_down() { _gt_region_extend_with down-line }

_gt_select_word_left() { _gt_region_extend_with _gt_word_left_vscode }
_gt_select_word_right() { _gt_region_extend_with _gt_word_right_vscode }

_gt_select_bol() { _gt_region_extend_with beginning-of-line }
_gt_select_eol() { _gt_region_extend_with end-of-line }
_gt_select_bob() { _gt_region_extend_with beginning-of-buffer-or-history }
_gt_select_eob() { _gt_region_extend_with end-of-buffer-or-history }

# Movement wrappers.
_gt_move_left() { _gt_move_with_clear backward-char }
_gt_move_right() { _gt_move_with_clear forward-char }
_gt_move_up() { _gt_move_with_clear up-line }
_gt_move_down() { _gt_move_with_clear down-line }

_gt_move_word_left() { _gt_move_with_clear _gt_word_left_vscode }
_gt_move_word_right() { _gt_move_with_clear _gt_word_right_vscode }

_gt_move_bol() { _gt_move_with_clear beginning-of-line }
_gt_move_eol() { _gt_move_with_clear end-of-line }
_gt_move_bob() { _gt_move_with_clear beginning-of-buffer-or-history }
_gt_move_eob() { _gt_move_with_clear end-of-buffer-or-history }

# Copy region to system clipboard (cmd+c -> CSI 99~ in Ghostty).
_gt_copy_region() {
  if (( REGION_ACTIVE )); then
    zle copy-region-as-kill
    print -rn -- "$CUTBUFFER" | pbcopy
  fi
}

# Register widgets.
zle -N _gt_select_left
zle -N _gt_select_right
zle -N _gt_select_up
zle -N _gt_select_down
zle -N _gt_select_word_left
zle -N _gt_select_word_right
zle -N _gt_select_bol
zle -N _gt_select_eol
zle -N _gt_select_bob
zle -N _gt_select_eob

zle -N _gt_move_left
zle -N _gt_move_right
zle -N _gt_move_up
zle -N _gt_move_down
zle -N _gt_move_word_left
zle -N _gt_move_word_right
zle -N _gt_word_left_vscode
zle -N _gt_word_right_vscode
zle -N _gt_move_bol
zle -N _gt_move_eol
zle -N _gt_move_bob
zle -N _gt_move_eob
zle -N _gt_copy_region

_gt_bind_keymap() {
  local keymap=$1
  local seq=$2
  local widget=$3

  if bindkey -M "$keymap" >/dev/null 2>&1; then
    bindkey -M "$keymap" "$seq" "$widget"
  fi
}

for keymap in emacs viins; do
  # Shift+Arrows: selection by character/line.
  _gt_bind_keymap "$keymap" "\e[1;2D" _gt_select_left
  _gt_bind_keymap "$keymap" "\e[1;2C" _gt_select_right
  _gt_bind_keymap "$keymap" "\e[1;2A" _gt_select_up
  _gt_bind_keymap "$keymap" "\e[1;2B" _gt_select_down

  # Shift+Option+Arrows: selection by word (VS Code separators).
  _gt_bind_keymap "$keymap" "\e[1;4D" _gt_select_word_left
  _gt_bind_keymap "$keymap" "\e[1;4C" _gt_select_word_right
  _gt_bind_keymap "$keymap" "\e[1;4A" _gt_select_up
  _gt_bind_keymap "$keymap" "\e[1;4B" _gt_select_down

  # Shift+Cmd+Arrows: selection to line/document bounds.
  _gt_bind_keymap "$keymap" "\e[1;10D" _gt_select_bol
  _gt_bind_keymap "$keymap" "\e[1;10C" _gt_select_eol
  _gt_bind_keymap "$keymap" "\e[1;10A" _gt_select_bob
  _gt_bind_keymap "$keymap" "\e[1;10B" _gt_select_eob

  # Shift+Home/End: selection to line bounds.
  _gt_bind_keymap "$keymap" "\e[1;2H" _gt_select_bol
  _gt_bind_keymap "$keymap" "\e[1;2F" _gt_select_eol

  # Option+Arrows: move by word (VS Code separators).
  _gt_bind_keymap "$keymap" "\e[1;3D" _gt_move_word_left
  _gt_bind_keymap "$keymap" "\e[1;3C" _gt_move_word_right
  _gt_bind_keymap "$keymap" "\e[1;3A" _gt_move_up
  _gt_bind_keymap "$keymap" "\e[1;3B" _gt_move_down

  # Cmd+Up/Down: document bounds (Ghostty sends ESC < / >).
  _gt_bind_keymap "$keymap" "\e<" _gt_move_bob
  _gt_bind_keymap "$keymap" "\e>" _gt_move_eob

  # Unmodified arrows: move and clear selection.
  _gt_bind_keymap "$keymap" "\e[D" _gt_move_left
  _gt_bind_keymap "$keymap" "\e[C" _gt_move_right
  _gt_bind_keymap "$keymap" "\e[A" _gt_move_up
  _gt_bind_keymap "$keymap" "\e[B" _gt_move_down
  _gt_bind_keymap "$keymap" "\eOD" _gt_move_left
  _gt_bind_keymap "$keymap" "\eOC" _gt_move_right
  _gt_bind_keymap "$keymap" "\eOA" _gt_move_up
  _gt_bind_keymap "$keymap" "\eOB" _gt_move_down

  # Alt sequences from some terminals.
  _gt_bind_keymap "$keymap" "\eb" _gt_move_word_left
  _gt_bind_keymap "$keymap" "\ef" _gt_move_word_right

  # Ctrl+A / Ctrl+E: line bounds.
  _gt_bind_keymap "$keymap" "^A" _gt_move_bol
  _gt_bind_keymap "$keymap" "^E" _gt_move_eol

  # cmd+c -> CSI 99~ copy region to clipboard.
  _gt_bind_keymap "$keymap" "\e[99~" _gt_copy_region
done
