# Ctrl+O: ask atuin AI for a shell command.
ask_atuin_ai() {
  setopt LOCAL_OPTIONS NO_NOTIFY NO_MONITOR

  if ! command -v atuin >/dev/null 2>&1; then
    print -r -- "atuin not found" > /dev/tty
    return 1
  fi

  local user_prompt="$BUFFER"
  [[ -z "$user_prompt" ]] && return

  zle kill-whole-line
  zle redisplay

  local output
  output=$(atuin ai inline --hook -- "$user_prompt" 3>&1 1>&2 2>&3)

  if [[ $output == __atuin_ai_print__:* ]]; then
    zle -I
    print -r -- "${output#__atuin_ai_print__:}" > /dev/tty
  elif [[ $output == __atuin_ai_cancel__ ]]; then
    BUFFER="$user_prompt"
    CURSOR=${#BUFFER}
    zle reset-prompt
  elif [[ $output == __atuin_ai_execute__:* ]]; then
    RBUFFER=""
    LBUFFER=${output#__atuin_ai_execute__:}
    zle reset-prompt
    zle accept-line
  elif [[ $output == __atuin_ai_insert__:* ]]; then
    RBUFFER=""
    LBUFFER=${output#__atuin_ai_insert__:}
    zle reset-prompt
  elif [[ -n $output ]]; then
    RBUFFER=""
    LBUFFER=$output
    zle reset-prompt
  else
    BUFFER="$user_prompt"
    CURSOR=${#BUFFER}
    zle reset-prompt
  fi
}

zle -N ask_atuin_ai
bindkey '^O' ask_atuin_ai
