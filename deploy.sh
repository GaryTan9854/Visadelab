#!/bin/bash
# Deploy Visadelab Portal to Mac Mini
# Source of truth: this repository
# Run this after editing index.html

set -e

# >>> TUNA-VERIFY
# ★ 同源區塊，**勿手改**。來源：~/Documents/deploy-verify.sh（改完跑 sync-deploy-verify.sh）
# 用法：tuna_verify <ssh目標> <port> <期望版本|空字串> [對外hostname]
tuna_verify() {
  local target="$1" port="$2" want="$3" host="${4:-}" h got pub
  h=$(ssh ${SSH_OPTS:-} "$target" "curl -s -m 8 http://127.0.0.1:$port/api/health" 2>/dev/null || true)
  if [ -z "$h" ]; then
    echo "   ❌ MBP 上 127.0.0.1:$port/api/health 沒有回應 —— app 沒有起來"
    return 1
  fi
  echo "   本機：$h"
  case "$h" in
    *'"status":"ok"'*) ;;
    *) echo "   ❌ health 沒有回 status:ok"; return 1 ;;
  esac
  got=$(printf '%s' "$h" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')
  if [ -n "$want" ]; then
    if [ -z "$got" ]; then
      echo "   ❌ health 沒有 version 欄位，無法確認跑的是新版（期望 v$want）"
      return 1
    fi
    if [ "$got" != "$want" ]; then
      echo "   ❌ 線上是 v$got，不是 v$want —— 舊行程還佔著，這次部署沒有生效"
      return 1
    fi
  fi
  [ -n "$host" ] || return 0
  pub=$(curl -s -m 12 -L "https://$host/api/health" 2>/dev/null || true)
  case "$pub" in
    *'"status":"ok"'*) echo "   對外：通（這站不需登入）" ;;
    *cloudflareaccess*|*"<html"*|*"<!DOCTYPE"*|*"Sign in"*|*"login"*)
      echo "   對外：Cloudflare Access 擋著，回的是登入頁（預期行為，不算失敗）" ;;
    "") echo "   對外：連不上（tunnel／DNS 待確認；本機已經驗過了，不影響成敗）" ;;
    *) echo "   對外：回了不是 health 的東西 → $(printf '%s' "$pub" | head -c 60)" ;;
  esac
}
# <<< TUNA-VERIFY

MBP="gary@192.168.1.11"
REMOTE_DIR="/Users/gary/portal-dist/"
SSH_KEY="$HOME/.ssh/id_ed25519"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
# tuna_verify 走 ssh，讓它用跟下面 rsync 同一把 key（不然它吃的是預設 ssh 設定）
SSH_OPTS="-i $SSH_KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=no"

cd "$REPO_DIR"

# ★ 版本（2026-09-28 補）：portal 以前沒有版本，所以 deploy 只能印「Done」，
#   沒辦法回答「線上跑的到底是我剛推的那份嗎」。照全站 SemVer 慣例來。
BUMP=patch
LAST_TAG=$(git describe --tags --abbrev=0 --match 'v*' 2>/dev/null || echo "")
SUBJ=$(git log ${LAST_TAG:+$LAST_TAG..}HEAD --pretty=%s 2>/dev/null || echo "")
echo "$SUBJ" | grep -qE '^(breaking:|[a-z]+(\([^)]*\))?!:)' && BUMP=major
[ "$BUMP" = "patch" ] && echo "$SUBJ" | grep -qE '^feat(\([^)]*\))?:' && BUMP=minor
BUILD_NUM=$(( $(git rev-list --count HEAD) + 1 ))
VERSION=$(BUMP="$BUMP" BUILD="$BUILD_NUM" node -e '
  const fs = require("fs");
  const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
  let [a, b, c] = String(p.version).split(".").map(Number);
  if (process.env.BUMP === "major") { a++; b = 0; c = 0; } else if (process.env.BUMP === "minor") { b++; c = 0; } else c++;
  p.version = `${a}.${b}.${c}`; p.build = Number(process.env.BUILD);
  fs.writeFileSync("package.json", JSON.stringify(p, null, 2) + "\n");
  process.stdout.write(p.version);')
echo "🔢 v$VERSION（$BUMP，build $BUILD_NUM）"

echo "📦 Committing changes..."
git add -A
git diff --cached --quiet && echo "No changes to commit" || git commit -m "update: $(date '+%Y-%m-%d %H:%M')"

git tag "v$VERSION" 2>/dev/null || true

echo "🚀 Pushing to GitHub..."
git push origin main --tags

# ★ appicon-*.png ＝ 那些在 Cloudflare Access 後面的 app 的 iPhone 主畫面圖示（2026-09-21）。
#   iPhone「加入主畫面」去抓 apple-touch-icon 時不帶 Access 的登入 cookie ⇒ 拿到 302 的登入頁，
#   圖示退回成一個字母（Gary 太太的 TunaSavoir 變成「T」）。放在公開的 visadelab.xyz 就不用 cookie。
echo "📡 Deploying to MacBook Pro..."
rsync -av \
  -e "ssh -i $SSH_KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=no" \
  "$REPO_DIR/index.html" \
  "$REPO_DIR/server.js" \
  "$REPO_DIR/package.json" \
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

echo "🩺 驗證線上跑的真的是新版（判成敗只認 MBP 本機 loopback）"
sleep 2
tuna_verify "$MBP" 3000 "$VERSION" "visadelab.xyz" || exit 1

echo "✅ portal v$VERSION → https://visadelab.xyz"
