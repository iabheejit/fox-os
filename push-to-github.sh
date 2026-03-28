#!/bin/bash
# Mr Fox CTO Skill — Push to GitHub
# Run this once from inside the mr-fox-cto folder

set -e

REPO_NAME="mr-fox-cto"
GITHUB_USER=$(gh api user --jq '.login' 2>/dev/null || git config --global user.name | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

echo "→ Creating GitHub repo: $GITHUB_USER/$REPO_NAME"
gh repo create "$REPO_NAME" \
  --public \
  --description "Mr Fox — CTO Operating System skill for Claude/Cowork" \
  --source=. \
  --remote=origin \
  --push

echo ""
echo "✓ Done! Repo live at: https://github.com/$GITHUB_USER/$REPO_NAME"
