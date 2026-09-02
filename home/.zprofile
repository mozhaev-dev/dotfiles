
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# ----RUST----
# The rustup formula keeps its shims out of Homebrew's default bin, so they
# have to be put on PATH by hand. Toolchains still live in ~/.rustup.

[ -d "$HOMEBREW_PREFIX/opt/rustup/bin" ] && \
	export PATH="$HOMEBREW_PREFIX/opt/rustup/bin:$PATH"

# ----MACHINE-LOCAL----

[ -r "$HOME/.zprofile.local" ] && source "$HOME/.zprofile.local"
