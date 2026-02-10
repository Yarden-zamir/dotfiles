alias copy="pbcopy"

alias dotform="dotnet format"

alias t=touch
alias create=touch

alias code.="code ."

alias edit="code"
alias edit.="code ."

alias cd.="cd $PWD"
alias cd..="cd .."
alias cd...="cd ../.."
alias cd....="cd ../../.."
alias cd.....="cd ../../../.."
alias cd......="cd ../../../../.."


alias cd/="cd /"
alias cd~="cd ~"
alias cd-="cd -"

alias open.="open ."

alias y=yay

alias @="xargs -L1 -P0"
alias @L1="xargs -L1 -P0"
alias @n1="xargs -n1 -P0"


alias for-each="xargs -L1 -P0"

alias count='wc -l'
alias ll='ls -l'

alias set_shell="chsh -s"

alias root='cd $(git rev-parse --show-toplevel || echo ".")'
alias .=root
