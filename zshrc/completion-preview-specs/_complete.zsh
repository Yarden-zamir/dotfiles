# :fzf-tab:complete:*
([ -d $word ] && et --dirs-first --icons --sort=name --scale=0 --level=4 $word) ||\
        bat --wrap=character --color=always --style=header $word