# :fzf-tab:complete:git-(add|diff|restore|cherry-pick):argument-rest
case $group in
'[untracked file]')
  bat $word --color=always --style full
  ;;
'[tree file]')
  less ${realpath#--*=}
  ;;
*)
  git diff $word | delta
  ;;
esac
