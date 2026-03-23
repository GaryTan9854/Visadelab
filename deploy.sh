#!/bin/bash
# Deploy Visadelab Portal to Mac Mini
# Source of truth: MacBook Air ~/Documents/visadelab_portal/
# Run this after editing index.html

set -e

MAC_MINI="garytan@192.168.1.10"
REMOTE_DIR="/Users/garytan/Visadelab_Portal/"
SSH_KEY="$HOME/.ssh/id_ed25519"

echo "📦 Committing changes..."
cd ~/Documents/visadelab_portal
git add -A
git diff --cached --quiet && echo "No changes to commit" || git commit -m "update: $(date '+%Y-%m-%d %H:%M')"

echo "🚀 Pushing to GitHub..."
git push origin main

echo "📡 Deploying to Mac Mini..."
rsync -av -e "ssh -i $SSH_KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=no" 
  index.html 
  $MAC_MINI:$REMOTE_DIR

echo "✅ Done! https://portal.visadelab.xyz"
