coursier_bin="$HOME/Library/Application Support/Coursier/bin"
if [[ -d $coursier_bin ]]; then
  export PATH="$PATH:$coursier_bin"
fi
unset coursier_bin
