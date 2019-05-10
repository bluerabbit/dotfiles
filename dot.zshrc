source ~/.zsh/config.zsh
source ~/.zsh/bindkey.zsh
source ~/.zsh/prompt.zsh
source ~/.zsh/aliases.zsh
source ~/.zsh/pbcopy-buffer.zsh
source ~/.zsh/ghq-fzf.zsh
source ~/.zsh/git-branch-fzf.zsh
source ~/.zsh/history-fzf.zsh
source ~/.zsh/ssh-fzf.zsh
source ~/.zsh/node-version.zsh
for f (~/.zsh/*.function) source "${f}"

#source ~/.zsh/auto-fu_enabled.zsh

# do brew install rbenv
eval "$(rbenv init -)"

# golang version manager
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"

# https://github.com/aziz/tmuxinator/
[[ -s $HOME/.tmuxinator/scripts/tmuxinator ]] && source $HOME/.tmuxinator/scripts/tmuxinator
