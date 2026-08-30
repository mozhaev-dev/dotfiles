#----ALIASES----

alias ll='eza -lah --git'
alias lt='eza --tree -lah --git'

#----SHELL----

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# Completion
autoload -Uz compinit
compinit

# Shell behavior
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS

# ----UTILS----

# fzf
source <(fzf --zsh)

# zoxide
eval "$(zoxide init zsh)"
