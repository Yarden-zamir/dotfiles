# :fzf-tab:complete:git-(add|diff|restore|cherry-pick):argument-rest
case $group in
'tree file')
  less ${realpath#--*=}
  ;;
*)
  git diff $word | delta
  ;;
esac
