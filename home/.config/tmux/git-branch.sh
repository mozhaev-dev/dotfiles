#!/bin/sh

# Print the branch for tmux's active pane. Outside a Git worktree, print
# nothing so the status bar does not contain an empty placeholder.
path=${1:-.}

git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

branch=$(git -C "$path" symbolic-ref --quiet --short HEAD 2>/dev/null) || \
	branch=$(git -C "$path" rev-parse --short HEAD 2>/dev/null) || exit 0

# A literal # has meaning in tmux formats, so double it before rendering.
branch=$(printf '%s' "$branch" | sed 's/#/##/g')
printf 'git:%s' "$branch"
