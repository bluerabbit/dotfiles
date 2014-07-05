function peco-select-history() {
    local tac
    if which tac > /dev/null; then
        tac="tac"
    else
        tac="tail -r"
    fi
    history -n 1 | eval $tac | peco
}
zle -N peco-select-history
bindkey '^r' peco-select-history
