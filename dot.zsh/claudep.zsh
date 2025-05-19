function claudep() {
  claude -p "$@" --output-format json | jq -r '.result'
}
