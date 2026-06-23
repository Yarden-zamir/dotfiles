export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

for candidate in scala sbt java; do
  candidate_bin="$SDKMAN_DIR/candidates/$candidate/current/bin"
  [[ -d "$candidate_bin" ]] && path=("$candidate_bin" ${path:#$candidate_bin})
done
export PATH
