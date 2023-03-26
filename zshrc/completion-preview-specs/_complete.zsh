# :fzf-tab:complete:*
# This is the default preview
([ -d $word ] && et --dirs-first --icons --sort=name --scale=0 --level=4 $word) ||\
        bat --wrap=character --color=always --style=header $word 2>/dev/null ||\
        echo $word