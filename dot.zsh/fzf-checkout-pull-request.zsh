
function fzf-checkout-pull-request () {
    local selected_pr_id=$(gh pr list | fzf | awk '{ print $1 }')
    if [ -n "$selected_pr_id" ]; then
        BUFFER="gh pr checkout ${selected_pr_id}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N fzf-checkout-pull-request
bindkey "^g^p" fzf-checkout-pull-request
