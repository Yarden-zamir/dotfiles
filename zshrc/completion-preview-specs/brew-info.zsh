# :fzf-tab:complete:brew-(install|uninstall|reinstall|upgrade|pin|unpin|link|unlink|info|cat|uses|dep):*

brew desc --eval-all $word | cut -d: -f2\
&& echo "\n# brew info:" && brew info $word | bat --color=always --style=plain --language=markdn \
&& echo "\n# brew log:" && brew log --stat --max-count 2 $word | bat --color=always --style=plain --language=markdn
