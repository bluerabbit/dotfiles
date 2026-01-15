export PATH=/usr/local/bin/:$PATH

# claude-code でターミナル名の自動変更を無効化
export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1

# homebrewでインストール禁止にする
export HOMEBREW_FORBIDDEN_FORMULAE="node yarn claude"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS="--height 100% --extended --cycle --reverse --ansi --border"
export FZF_CTRL_T_OPTS='--preview "bat  --color=always --style=header,grid --line-range :100 {}"'
