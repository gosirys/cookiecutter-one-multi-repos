#!/usr/bin/env bash
set -euo pipefail

CONFIG=submodules.txt
TARGET=modules

if [[ ! -f "$CONFIG" ]]; then
	echo "✖  Copy submodules.txt.example → submodules.txt and edit it"
	exit 1
fi

mkdir -p "$TARGET"
while IFS=$'\n' read -r repo; do
	[[ -z "$repo" || "${repo:0:1}" == "#" ]] && continue
	name=$(basename -s .git "$repo")
	echo "⤷ Adding $name from $repo"
	git submodule add "$repo" "$TARGET/$name"
done < "$CONFIG"

git submodule update --init --recursive
echo "✔  All submodules added under $TARGET/"