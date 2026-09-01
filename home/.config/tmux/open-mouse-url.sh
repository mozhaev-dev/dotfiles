#!/usr/bin/env bash
#
# Opens the URL under the mouse cursor. Called from the Ctrl+click binding in
# tmux.conf, which passes the click column, the clicked line and the OSC 8
# hyperlink (if the terminal reported one).
#
# Every argument carries a one-letter prefix so that an empty value still
# arrives as an argument instead of silently shifting the rest along.
#
#   open-mouse-url.sh X<column> L<line> H<hyperlink>

set -uo pipefail

col="${1-X0}"; col="${col#X}"
line="${2-}"; line="${line#L}"
hyperlink="${3-}"; hyperlink="${hyperlink#H}"

# A real hyperlink beats anything we could guess from the text.
if [[ -n "$hyperlink" ]]; then
	open "$hyperlink"
	exit 0
fi

URL_RE='(https?://|www\.)[^[:space:]<>"'"'"'`]+'
TRAILING_RE='[.,;:!?'"'"'"]$'

# Trailing punctuation is almost always sentence punctuation, not part of the
# URL. A closing bracket is kept only when the URL opens one itself.
trim() {
	local url="$1"
	while [[ "$url" =~ $TRAILING_RE ]] ||
		{ [[ "$url" == *')' ]] && [[ "$url" != *'('* ]]; }; do
		url="${url%?}"
	done
	# `open` needs a scheme, and a bare www.… host has none.
	[[ "$url" == www.* ]] && url="https://$url"

	printf '%s' "$url"
}

# Walk every URL on the line, tracking where each one starts, and take the one
# the click landed inside.
rest="$line"
offset=0
found=()
while [[ "$rest" =~ $URL_RE ]]; do
	match="${BASH_REMATCH[0]}"
	before="${rest%%"$match"*}"
	start=$((offset + ${#before}))
	end=$((start + ${#match}))

	if ((col >= start && col < end)); then
		open "$(trim "$match")"
		exit 0
	fi

	found+=("$match")
	rest="${rest:${#before}+${#match}}"
	offset=$end
done

# Clicked next to the link rather than on it: unambiguous if the line holds
# exactly one URL.
if ((${#found[@]} == 1)); then
	open "$(trim "${found[0]}")"
fi

exit 0
