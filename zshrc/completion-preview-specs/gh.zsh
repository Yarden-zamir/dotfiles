# :fzf-tab:complete:gh:
query="$words$word"
query=${${query%%--*}%% } # remove options and trailing space
echo $query --help | bat --color=always -plhelp