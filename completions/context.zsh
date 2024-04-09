_context() {
    local state

    _arguments \
        '*: :->eb_name'

    case $state in
    *) compadd "$@" $(ls "$CONTEXTS_DIR") ;;
    esac
}
compdef _context context
# compdef _kubeconfig sde-connect
