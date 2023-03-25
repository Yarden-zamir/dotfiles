# :fzf-tab:complete:(\\|*/|)man:
run-help $word > /dev/null 2>&1 && run-help $word | bat --color=always -pl Manpage || $word --help
