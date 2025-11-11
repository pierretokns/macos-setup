#!/bin/bash
set -e

# Base directory to clone into
CLONE_DIR="$HOME/sundai"
mkdir -p "$CLONE_DIR"

# List of GitHub repos to fork and clone
repos=(
  "obra/superpowers"
  "disler/claude-code-hooks-multi-agent-observability"
  "ruvnet/claude-flow"
  "Significant-Gravitas/AutoGPT"
  "eyaltoledano/claude-task-master"
)

echo "Starting fork and clone process..."

for repo in "${repos[@]}"; do
  echo "Forking $repo ..."
  # Fork repo, no clone yet
echo "y" | gh repo fork "$repo" --remote=false

# Construct fork repo URL based on your username
# Get your GitHub username via gh API
USERNAME=$(gh api user --jq '.login')
FORK_REPO_URL="https://github.com/$USERNAME/$(basename $repo).git"

echo "Cloning fork $FORK_REPO_URL into $CLONE_DIR/$(basename $repo)..."
git clone "$FORK_REPO_URL" "$CLONE_DIR/$(basename $repo)"
done

echo "All repositories forked and cloned into $CLONE_DIR"
