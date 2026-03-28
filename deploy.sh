#!/bin/bash
# Deploy Visadelab Portal to Mac Mini
# Source of truth: this repository
# Run this after editing index.html

set -e

MBP="gary@192.168.1.11"
REMOTE_DIR="/Users/gary/Visadelab_Portal/"
SSH_KEY="$HOME/.ssh/id_ed25519"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "📦 Committing changes..."
cd "$REPO_DIR"
git add -A
git diff --cached --quiet && echo "No changes to commit" || git commit -m "update: $(date '+%Y-%m-%d %H:%M')"

echo "🚀 Pushing to GitHub..."
git push origin main

echo "📡 Deploying to MacBook Pro..."
rsync -av \
  -e "ssh -i $SSH_KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=no" \
  "$REPO_DIR/index.html" \
  "$MBP:$REMOTE_DIR"

echo "✅ Done! https://portal.visadelab.xyz"
