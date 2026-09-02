#!/usr/bin/env bash
#
# Links every file under home/ into $HOME, creates the machine-local override
# files this repo's configs expect, and completes the Rust toolchain that
# Brewfile's rustup cannot set up on its own. Idempotent: safe to re-run.
#
#   ./install.sh          link everything
#   ./install.sh --dry-run   show what would happen, change nothing

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_TREE="$REPO_DIR/home"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

# Machine-local override files. Never tracked here: they live in $HOME only.
# Every shared config loads its matching local file at the point where the
# application's precedence rules make the local settings win.
LOCAL_FILES=(
	".zshrc.local"
	".zprofile.local"
	".config/git/config.local"
	".config/tmux/tmux.local.conf"
	".config/ghostty/config.local"
	".config/nvim/local.lua"
	".ssh/config.local"
)
PRIVATE_LOCAL_FILES=(
	".secrets.zsh"
	".ssh/config.local"
)

run() {
	if (( DRY_RUN )); then
		printf '      would: %s\n' "$*"
	else
		"$@"
	fi
}

backup() {
	local target="$1" rel="$2"
	run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
	run mv "$target" "$BACKUP_DIR/$rel"
}

link_tree() {
	local source rel target
	while IFS= read -r source; do
		rel="${source#"$HOME_TREE"/}"
		target="$HOME/$rel"

		if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
			printf '  ok    %s\n' "$rel"
			continue
		fi

		if [[ -e "$target" || -L "$target" ]]; then
			printf '  back  %s -> %s\n' "$rel" "${BACKUP_DIR/#"$HOME"/\~}/$rel"
			backup "$target" "$rel"
		fi

		printf '  link  %s\n' "$rel"
		run mkdir -p "$(dirname "$target")"
		run ln -s "$source" "$target"
	done < <(find "$HOME_TREE" -type f | sort)
}

seed_local_files() {
	local rel target comment
	for rel in "${LOCAL_FILES[@]}" "${PRIVATE_LOCAL_FILES[0]}"; do
		target="$HOME/$rel"

		if [[ -e "$target" ]]; then
			printf '  ok    %s\n' "$rel"
			continue
		fi

		# Lua files need Lua comments; everything else here is #-commented.
		comment='#'
		[[ "$rel" == *.lua ]] && comment='--'

		printf '  seed  %s\n' "$rel"
		run mkdir -p "$(dirname "$target")"
		if (( DRY_RUN )); then
			printf '      would: write header into %s\n' "$target"
		else
			printf '%s Machine-local overrides. Not tracked in the dotfiles repo.\n' "$comment" > "$target"
		fi
	done

	# Secrets and machine-specific SSH hosts can contain sensitive data.
	for rel in "${PRIVATE_LOCAL_FILES[@]}"; do
		run chmod 600 "$HOME/$rel"
	done
}

# Homebrew's rustup formula is not on PATH until a login shell has re-read
# .zprofile, so resolve the shim directly before falling back to the PATH.
find_rustup() {
	local brew_rustup="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/rustup/bin/rustup"

	if [[ -x "$brew_rustup" ]]; then
		printf '%s\n' "$brew_rustup"
	else
		command -v rustup || true
	fi
}

install_rust() {
	local rustup components
	rustup="$(find_rustup)"

	if [[ -z "$rustup" ]]; then
		printf '  skip  rustup missing — run `brew bundle` first\n'
		return
	fi
	printf '  ok    rustup  %s\n' "${rustup/#"$HOME"/\~}"

	if "$rustup" show active-toolchain >/dev/null 2>&1; then
		printf '  ok    toolchain\n'
	else
		printf '  add   stable toolchain\n'
		run "$rustup" default stable
	fi

	# rustup keeps a shim for rust-analyzer whether or not the component is
	# installed, so a missing one passes every check and fails only when the
	# editor starts the server.
	components="$("$rustup" component list --installed 2>/dev/null || true)"

	if grep -q '^rust-analyzer' <<<"$components"; then
		printf '  ok    rust-analyzer\n'
	else
		printf '  add   rust-analyzer\n'
		run "$rustup" component add rust-analyzer
	fi
}

main() {
	(( DRY_RUN )) && printf 'DRY RUN — nothing will be changed.\n\n'

	printf 'Linking %s -> %s\n' "${HOME_TREE/#"$HOME"/\~}" '~'
	link_tree

	printf '\nMachine-local files\n'
	seed_local_files

	printf '\nRust toolchain\n'
	install_rust

	if [[ -d "$BACKUP_DIR" ]]; then
		printf '\nReplaced files saved in %s\n' "${BACKUP_DIR/#"$HOME"/\~}"
	fi

	printf '\nDone. Open a new shell to pick up the changes.\n'
}

main "$@"
