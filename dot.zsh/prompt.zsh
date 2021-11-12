unsetopt promptcr
setopt prompt_subst
autoload -U colors; colors
autoload -Uz vcs_info

local HOSTNAME_COLOR=$'%{\e[38;5;190m%}'
local USERNAME_COLOR=$'%{\e[38;5;199m%}'
local PATH_COLOR=$'%{\e[38;5;61m%}'
local RUBY_COLOR=$'%{\e[38;5;31m%}'
local VCS_COLOR=$'%{\e[38;5;248m%}'

zstyle ':vcs_info:*' formats '[%b]'
zstyle ':vcs_info:*' actionformats '[%b] (%a)'

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr '¹'  # display ¹ if there are unstaged changes
zstyle ':vcs_info:git:*' stagedstr '²'    # display ² if there are staged changes
zstyle ':vcs_info:git:*' formats '[%b]%c%u'
zstyle ':vcs_info:git:*' actionformats '[%b|%a]%c%u'

function ruby_prompt {
    result=`rbenv version | sed -e 's/ .*//'`
    if [ "$result" ] ; then
        echo "[$result]"
    fi
}

function git_stash_count {
    result=`git stash list 2>/dev/null | wc -l | tr -d ' '`
    if [ "$result" != 0 ] ; then
  echo " stash:$result"
    fi
}

precmd () {
    psvar=()
    vcs_info
    [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
}

RUBY_INFO=$'%{$RUBY_COLOR%}$(ruby_prompt)%{${reset_color}%}'
RPROMPT="${RUBY_INFO}%{${reset_color}%}"
PROMPT=$'%{$fg[yellow]%}%n%{$fg[red]%}@$fg[green]%}%m$(echo "(`uname -m`)")%{$fg[cyan]%}%~ %1(v|%F{green}%1v%f|)$(git_stash_count)\n%{$fg[green]%}%#%{$reset_color%}'
setopt transient_rprompt
