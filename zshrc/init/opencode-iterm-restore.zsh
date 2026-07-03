if [[ -o interactive && "$TERM_PROGRAM" == "iTerm.app" && "$OPENCODE_ITERM_AUTO_RESTORE" == "1" && -z "$OPENCODE_ITERM_RESTORE_DONE" ]]; then
  export OPENCODE_ITERM_RESTORE_DONE=1

  restore_id="$($DOTFILES/bin/opencode-iterm-restore-id 2>/dev/null)"
  if [[ "$restore_id" == ses_* ]]; then
    opencode -s "$restore_id"
  fi

  unset restore_id
fi
