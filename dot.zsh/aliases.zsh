alias vi="vim"
alias view="vim -R"
alias subl='reattach-to-user-namespace subl' # brew install reattach-to-user-namespace
alias diff=colordiff
alias ls='ls -GF'
alias la='ls -a'
alias ll='ls -al'
alias cdp='cd -P'
alias tm="tmux -2 attach"
alias tailf="tail -f"
# alias less="less -qNRS"
alias less='less -qRS --no-init --quit-if-one-screen'
alias l='ls -CF'
alias dir='ls -al'
alias h='history'
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# node.js
alias ni='npm install'

# ディレクトリの履歴
alias gd='dirs -v; echo -n "select number: "; read newdir; cd -"$newdir"'
alias emacs='emacs -nw'

# for mac
alias fcd='source ~/bin/fcd.sh'
alias here='open .'

# for bundler
alias be='bundle exec'
alias bu='bundle update'
alias bi='bundle install'

# for rspec
alias br='bundle exec rspec '

alias clup="find -E . -regex '.*\/(#.*#|.*~)' -print0 |xargs -0 rm"

alias g='git'
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias gg='git grep'

# for mac applications
alias ce='open -a /Applications/Emacs.app/Contents/MacOS/Emacs'

alias wget="wget --output-file=$HOME/.wget.log --append-output=$HOME/.wget.log"

# alias -s(suffix alias) http://goo.gl/JSh6A
if [ `uname` = "Darwin" ]; then
  alias google-chrome='open -a Google\ Chrome'
fi
alias chrome='google-chrome'

alias -s html=chrome

function extract() {
  case $1 in
    *.tar.gz|*.tgz) tar xzvf $1;;
    *.tar.xz) tar Jxvf $1;;
    *.zip) unzip $1;;
    *.lzh) lha e $1;;
    *.tar.bz2|*.tbz) tar xjvf $1;;
    *.tar.Z) tar zxvf $1;;
    *.gz) gzip -dc $1;;
    *.bz2) bzip2 -dc $1;;
    *.Z) uncompress $1;;
    *.tar) tar xvf $1;;
    *.arj) unarj $1;;
  esac
}
alias -s {gz,tgz,zip,lzh,bz2,tbz,Z,tar,arj,xz}=extract

function runcpp () { g++ -O2 $1; ./a.out }
alias -s {c,cpp}=runcpp

# require 'p.function'
alias o='git ls-files | p open'

alias gb='git branch | p git checkout'
