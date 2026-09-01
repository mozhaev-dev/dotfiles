
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# ----MACHINE-LOCAL----

[ -r "$HOME/.zprofile.local" ] && source "$HOME/.zprofile.local"
