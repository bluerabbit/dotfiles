# ディレクトリ変更で自動的にnodebrewのnodeバージョンを変更する
function chpwd_node_version() {
  if [ -e ".node-version" ]; then
    version=`cat .node-version`
    nodebrew use $version
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd chpwd_node_version
