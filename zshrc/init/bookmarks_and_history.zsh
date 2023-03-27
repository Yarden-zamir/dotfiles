# Source https://github.com/junegunn/fzf/wiki/examples#google-chrome

chrome_history() {
  local cols sep google_history open
  cols=$(( COLUMNS / 3 ))
  sep='{::}'

  if [ "$(uname)" = "Darwin" ]; then
    google_history="$HOME/Library/Application Support/Google/Chrome/Default/History"
    open=open~
  else
    google_history="$HOME/.config/google-chrome/Default/History"
    open=xdg-open
  fi
  cp -f "$google_history" /tmp/h
  sqlite3 -separator $sep /tmp/h \
    "select substr(title, 1, $cols), url, datetime(last_visit_time / 1000000 - 11644473600, 'unixepoch')
     from urls order by last_visit_time desc" |
  awk -F $sep '{printf "%s  %-'$cols's  \x1b[36m%s\x1b[m\n", $3, $1, $2}' |
  fzf --ansi --multi | sed 's#.*\(https*://\)#\1#' | xargs $open > /dev/null 2> /dev/null
}

chrome_bookmark() {
     bookmarks_path=~/Library/Application\ Support/Google/Chrome/Default/Bookmarks

     jq_script='
        def ancestors: while(. | length >= 2; del(.[-1,-2]));
        . as $in | paths(.url?) as $key | $in | getpath($key) | {name,url,date_added: (.date_added | tonumber), path: [$key[0:-2] | ancestors as $a | $in | getpath($a) | .name?] | reverse | join("/") } | .date_added |= (. - 11644473600) | .path + "/" + .name + "\t" + .url + "\t" + (.date_added|tostring)'

    jq -r "$jq_script" < "$bookmarks_path" \
        | sed -E $'s/(.*)\t(.*)\t(.*)/\\3\t\\1\t\x1b[36m\\2\x1b[m/g' \
        | sort -nr \
        | fzf --ansi \
        | cut -d$'\t' -f3 \
        | xargs open
}

