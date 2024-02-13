loop() {
  while true; do
    "$@" # Executes all arguments as a single command
    sleep 1 # Optional: Prevents the loop from consuming too much CPU
  done
}