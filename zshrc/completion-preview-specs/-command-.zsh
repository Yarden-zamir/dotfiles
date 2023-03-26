# :fzf-tab:complete:(-command-:|command:option-(v|V)-rest)
# some logic taken from https://github.com/fluxninja/dotfiles/blob/master/dot_zshrc
export COLUMNS=$(($FZF_PREVIEW_COLUMNS - 2))
case $group in
'[external command]'|'[executable file]'|'[builtin command]'|['builtin command'])
  (out=$(tldr "$word") 2>/dev/null && echo $out) ||\
  (out=$(man $word) 2>/dev/null && echo $out) ||\
  (out=$($word --help) 2>/dev/null && echo $out) ||\
  (out=$(which "$word") && echo $out) ||\
  echo "$word"
  ;;
parameter)
  echo ${(P)word}
  ;;
esac
