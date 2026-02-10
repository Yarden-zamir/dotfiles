_evalcache starship init zsh


# # transient prompt based on https://github.com/starship/starship/issues/888
# set-long-prompt() {
#      PROMPT=$(starship prompt) 
# }
# precmd_functions=(set-long-prompt)

# set-short-prompt() {
#   if [[ $PROMPT != '%# ' ]]; then
#       PROMPT=""
#     zle .reset-prompt
#   fi
# }

# zle-line-finish() { 
#     set-short-prompt 
# }
# zle -N zle-line-finish

# trap 'set-short-prompt; return 130' INT
