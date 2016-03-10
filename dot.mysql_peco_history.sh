#!/bin/zsh
export LANG=C
BUFFER=$(sed -e "s/\\040/ /g" $MYSQL_HISTFILE | sed -e 's/\\//g' | egrep ";$" | egrep -i "^select|^update|^insert|^show|^commit|^use|^pager|^desc" | awk '!a[$0]++' | peco)
echo $BUFFER | tr -d '\n' | pbcopy
