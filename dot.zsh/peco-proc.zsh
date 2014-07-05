function peco-proc () {
    ps ax -o pid,lstart,command | peco --query "$LBUFFER" | awk '{print $1}' | xargs kill
    zle clear-screen
}
zle -N peco-proc
bindkey '^x^p' peco-proc
