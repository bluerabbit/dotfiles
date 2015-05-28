# http://blog.kenjiskywalker.org/blog/2014/06/12/peco/
# http://qiita.com/uchiko/items/f6b1528d7362c9310da0
# http://qiita.com/wada811/items/78b14181a4de0fd5b497

function peco-select-history() {
    local tac
    if which tac > /dev/null; then
        tac="tac"
    else
        tac="tail -r"
    fi
    BUFFER=$(history -n 1 | eval $tac | awk '!a[$0]++' | peco --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history
