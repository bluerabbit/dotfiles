alias vi="vim"
alias diff=colordiff
alias ls='ls -GF'
alias la='ls -a'
alias ll='ls -al'
# alias less="less -qNRS"
alias less='less -qRS --no-init --quit-if-one-screen'
alias l='ls -CF'
alias dir='ls -al'
alias h='history'
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'
alias ag='ag -u'

alias emacs='emacs -nw'

# for mac
alias fcd='source ~/bin/fcd.sh'
alias here='open .'

# for bundler
alias be='bundle exec'
alias bu='bundle update'
alias bi='bundle install'

alias g='git'
alias gpr='git stash && git pull --rebase && git stash pop'
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias gg='git grep'
alias gs="git status" # よくミスするtypoを補正

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
alias gb='git branch | p git checkout'

# docker for mac http://qiita.com/shinespark/items/526b70b5f0b1ac643ba0
alias rm_docker_images='docker images -qf dangling=true | xargs docker rmi'
alias rm_docker_containers='docker ps -aqf status=exited | xargs docker rm -v' # rm with volumes
alias rm_docker_volumes='docker volume ls -qf dangling=true | xargs docker volume rm'
alias rm_docker_compose_containers='docker-compose rm -fv'
