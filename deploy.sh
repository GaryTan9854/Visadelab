#!/bin/bash

MAC_MINI_HOST="garytan@TANde-Mac-mini.local"
MAC_MINI_DIR="~/visadelab_portal"

echo "🚀 Deploying Visadelab Portal..."

# ── 1. Git commit & push ──────────────────────────────────────
cd ~/Documents/visadelab_portal   # ← 改成你 MacBook Air 上的 repo 路徑

if [ -n "$(git status --porcelain)" ]; then
  echo "📦 Git commit & push..."
  git add .
  git commit -m "deploy: $(date '+%Y-%m-%d %H:%M')"
  git push
else
  echo "✅ Git: 無變更"
fi

# ── 2. rsync to Mac Mini ──────────────────────────────────────
echo "📡 Syncing to Mac Mini..."

rsync -av --delete \
  --exclude='.git/' \
  --exclude='deploy.sh' \
  ~/Documents/visadelab/ "$MAC_MINI_HOST:$MAC_MINI_DIR/"

echo "✅ Deploy 完成！"
echo "🌐 https://visadelab.xyz"
