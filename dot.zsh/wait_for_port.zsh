function wait_for_port {
    ruby -e 'while `lsof -i:#{'$1'}`.size.zero? do; sleep 1; end'
}
