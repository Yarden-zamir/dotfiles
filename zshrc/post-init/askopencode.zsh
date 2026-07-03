#credit: https://github.com/andreacasarin/zsh-ask-opencode
: ${ASK_OPENCODE_MODEL:="openai/gpt-5.3-codex-spark"}
: ${ASK_OPENCODE_DEBUG:=}

# Spinner animation
_ask_opencode_spinner() {
  local prompt="$1"
  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  while true; do
    printf "\r${spinstr:0:1} Asking OpenCode for '$prompt'..." > /dev/tty
    spinstr="${spinstr:1}${spinstr:0:1}"
    sleep 0.1
  done
}

# Trim whitespace from string
_ask_opencode_trim() {
  local str="$1"
  str="${str#"${str%%[![:space:]]*}"}"
  str="${str%"${str##*[![:space:]]}"}"
  print -r -- "$str"
}

# Show spinner and run command
_ask_opencode_run_with_spinner() {
  local prompt="$1"
  shift

  _ask_opencode_spinner "$prompt" &
  local spinner_pid=$!

  local output
  output=$("$@" 2>&1)
  local exit_code=$?

  { kill $spinner_pid && wait $spinner_pid } 2>/dev/null
  printf "\r\033[K" > /dev/tty

  print -r -- "$output"
  return $exit_code
}

# Main widget
ask_opencode() {
  setopt LOCAL_OPTIONS NO_NOTIFY NO_MONITOR

  local user_prompt="$BUFFER"
  [[ -z "$user_prompt" ]] && return

  zle kill-whole-line
  zle redisplay

  # Generate commands
  local output
  output=$(_ask_opencode_run_with_spinner "$user_prompt" opencode run --model "$ASK_OPENCODE_MODEL" \
    "Generate exactly 3 shell commands for this request:
$user_prompt

Output only these 3 lines, ranked by speed, safety, and reliability:
CMD: command1
CMD: command2
CMD: command3")

  if [[ $? -ne 0 ]]; then
    print -r -- "Error: $output" > /dev/tty
    BUFFER="$user_prompt"
    CURSOR=${#BUFFER}
    zle reset-prompt
    return 1
  fi

  if [[ "$ASK_OPENCODE_DEBUG" == "1" ]]; then
    print -r -- "[ask_opencode] Raw output:" > /dev/tty
    print -r -- "$output" | nl -ba > /dev/tty
  fi

  local line command
  local -a commands
  for line in "${(@f)output}"; do
    line="$(_ask_opencode_trim "$line")"
    [[ "$line" == "CMD:"* ]] || continue

    command="${line#CMD:}"
    command="$(_ask_opencode_trim "$command")"
    [[ -n "$command" ]] && commands+=("$command")
    [[ ${#commands[@]} -eq 3 ]] && break
  done

  if [[ "$ASK_OPENCODE_DEBUG" == "1" ]]; then
    print -r -- "[ask_opencode] Parsed commands:" > /dev/tty
    print -r -l -- "${commands[@]}" | nl -ba > /dev/tty
  fi

  if [[ ${#commands[@]} -eq 0 ]]; then
    print -r -- "No commands generated. Set ASK_OPENCODE_DEBUG=1 to inspect OpenCode output." > /dev/tty
    BUFFER="$user_prompt"
    CURSOR=${#BUFFER}
    zle reset-prompt
    return 1
  fi

  local selected="${commands[1]}"
  if command -v fzf >/dev/null 2>&1; then
    selected=$(print -r -l -- "${commands[@]}" | \
      fzf --height=10% --reverse --prompt="$user_prompt > " --border) || {
      BUFFER="$user_prompt"
      CURSOR=${#BUFFER}
      zle reset-prompt
      return 0
    }
  fi

  BUFFER="$selected"
  CURSOR=${#BUFFER}
  zle reset-prompt
}

ask_atuin_ai() {
  setopt LOCAL_OPTIONS NO_NOTIFY NO_MONITOR

  if ! command -v atuin >/dev/null 2>&1; then
    print -r -- "atuin not found; falling back to ask_opencode" > /dev/tty
    ask_opencode
    return $?
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

zle -N ask_opencode
zle -N ask_atuin_ai
bindkey '^O' ask_atuin_ai
