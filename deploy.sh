#!/bin/bash
# Deploy Visadelab Portal to Mac Mini
# Source of truth: this repository
# Run this after editing index.html

set -e

MBP="gary@192.168.1.11"
REMOTE_DIR="/Users/gary/portal-dist/"
SSH_KEY="$HOME/.ssh/id_ed25519"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "📦 Committing changes..."
cd "$REPO_DIR"
git add -A
git diff --cached --quiet && echo "No changes to commit" || git commit -m "update: $(date '+%Y-%m-%d %H:%M')"

echo "🚀 Pushing to GitHub..."
git push origin main

# ★ appicon-*.png ＝ 那些在 Cloudflare Access 後面的 app 的 iPhone 主畫面圖示（2026-09-21）。
#   iPhone「加入主畫面」去抓 apple-touch-icon 時不帶 Access 的登入 cookie ⇒ 拿到 302 的登入頁，
#   圖示退回成一個字母（Gary 太太的 TunaSavoir 變成「T」）。放在公開的 visadelab.xyz 就不用 cookie。
echo "📡 Deploying to MacBook Pro..."
rsync -av \
  -e "ssh -i $SSH_KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=no" \
  "$REPO_DIR/index.html" \
  "$REPO_DIR/server.js" \
  "$REPO_DIR/gag-icon.png" \
  "$REPO_DIR/manifest.json" \
  "$REPO_DIR/sw.js" \
  "$REPO_DIR/pwa.js" \
  "$REPO_DIR/icon-180.png" \
  "$REPO_DIR/icon-192.png" \
  "$REPO_DIR/icon-512.png" \
  "$REPO_DIR/icon-maskable-512.png" \
  "$REPO_DIR"/appicon-*.png \
  "$MBP:$REMOTE_DIR"

echo "🔄 Restarting portal (PM2)..."
ssh -i "$SSH_KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=no "$MBP" \
  'export NVM_DIR="$HOME/.nvm"; source $NVM_DIR/nvm.sh; pm2 restart portal'

echo "✅ Done! https://portal.visadelab.xyz"
