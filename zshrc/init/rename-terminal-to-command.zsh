function preexec {
    print -Pn "\e]0;${(q)1}\e\\"
}