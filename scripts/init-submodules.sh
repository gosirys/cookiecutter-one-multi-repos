#!/usr/bin/env bash
set -euo pipefail

CONFIG=submodules.txt
TARGET=modules

# Ensure GitHub CLI is available and authenticated
if ! command -v gh &>/dev/null; then
	echo "✖ Install and authenticate GitHub CLI: https://cli.github.com/"
	exit 1
fi

# Prompt for a PAT (repo scope)
read -rsp "Enter your GitHub PAT (repo scope): " SUBMODULE_PAT
echo

# Store PAT as a repository secret in the new repo
REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
gh secret set SUBMODULE_PAT --body "$SUBMODULE_PAT" --repo "$REPO"

# Grant Actions permission and whitelist private submodules
# Adjust PRIVATE_SUBMODULES array if specific repos need to be selected
PRIVATE_SUBMODULES=()
# Example: PRIVATE_SUBMODULES+=( "org/repo-one" "org/repo-two" )

gh api \
	-X PUT "/repos/$REPO/actions/permissions/workflow" \
	-f default_workflow_permissions=write \
	-f allowed_actions=selected \
	-f selected_repositories="$(printf '%s\n' "${PRIVATE_SUBMODULES[@]}" | paste -sd, -)" \
	--silent

echo "✔ SUBMODULE_PAT secret created and workflow permissions updated."

# Add each repository listed in submodules.txt
if [[ ! -f "$CONFIG" ]]; then
	echo "✖ Copy submodules.txt.example to submodules.txt and edit it"
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
echo "✔ All submodules added under $TARGET/"