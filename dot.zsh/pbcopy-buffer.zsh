## http://d.hatena.ne.jp/hiboma/20120315/1331821642
## Ctrl + X Crtl + Pでコマンドラインをクリップボードに登録
pbcopy-buffer(){
    print -rn $BUFFER | pbcopy
    zle -M "pbcopy: ${BUFFER}"
}

zle -N pbcopy-buffer
bindkey '^x^p' pbcopy-buffer
