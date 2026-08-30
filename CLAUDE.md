# Visadelab Portal

`portal.visadelab.xyz` 的原始碼。這個 repo **只包含入口首頁本身**——一張列出所有
Visadelab 應用的牌卡頁，加一個零依賴的 Node 靜態伺服器。牌卡指向的那些 app
（TunaSpend、TunaNote、TunaTCM…）各自有獨立的 repo，不在這裡。

## 檔案

| 檔案 | 用途 |
|---|---|
| `index.html` | 整個首頁。CSS、SVG icon、版本抓取的 JS 全部 inline，沒有 build step |
| `server.js` | PM2 上的 `portal` 程序（port 3000）。靜態檔 + `/api/versions` 聚合 |
| `gag-icon.png` | GAG Risk Report 牌卡的圖，唯一的外部圖檔 |
| `deploy.sh` | commit + push + rsync 到 MBP + 重啟 PM2 |

沒有 `package.json`、沒有 node_modules、沒有測試。`server.js` 只用 Node 內建模組，
直接 `node server.js` 就能跑。

## 兩個必須同步的清單

新增或移除牌卡時，**兩個地方都要改**：

1. `index.html` 裡該牌卡的 `data-app="<key>"`
2. `server.js` 的 `APP_PORTS` 裡對應的 `<key>: <port>`

漏掉 (2)，牌卡不會顯示版本號；漏掉 (1)，每分鐘白打一次 health check。
目前兩邊各 14 個 key，完全一致——改動後請確認仍然一致。

沒有版本號的牌卡是刻意的：`card-dim`（TunaSavoir、Bloomberg Connect）是還沒上線的
佔位，Telegram Bot 那張沒有網址。`server.js` 的註解裡記著 2026-08-05 下架的牌卡，
那些 app 仍在跑，只是首頁不再列出。

## `/api/versions` 怎麼運作

`server.js` 對 `127.0.0.1:<port>/api/health` 逐一 fetch，快取 60 秒。走 localhost，
不經過 Cloudflare/Access。每個 app 要回 `{ version, build }` 才會顯示；逾時 2 秒，
失敗就靜默略過（牌卡照樣可點，只是沒版本號）。

首頁的 fetch 失敗也是靜默的，所以「版本號沒出來」通常代表某個 app 掛了或沒實作
`/api/health`，不是首頁壞了。

## 部署

```bash
./deploy.sh
```

**注意這支腳本的副作用**，它不只是部署：

- `git add -A` + commit（訊息固定是 `update: <日期時間>`）+ push 到 `main`。
  工作目錄裡所有未提交的東西都會一起被送上去。
- 只 rsync **三個檔案**：`index.html`、`server.js`、`gag-icon.png`。
  新增任何其他檔案，commit 進得去，但**不會被部署**——要自己加進 rsync 清單。
- rsync 目標 `gary@192.168.1.11:/Users/gary/portal-dist/`，然後 `pm2 restart portal`。

**遠端 session（Claude Code on the web、沙盒 VM）跑不了這支腳本**——
`192.168.1.11` 是家用內網，沙盒完全連不到。遠端只能改程式碼並 push；
實際部署要在 Gary 的 Mac 上執行，或透過 `connect-server-skill` 走 osascript。

## 已知的髒東西

- **`telegram-bot/`、`telegram-bot-github/` 是本地獨立的 git repo**，不屬於這個 repo。
  它們曾經被誤加成 gitlink（且沒有 `.gitmodules`），2026-08 已清掉並加進 `.gitignore`。
  **不要把 `.gitignore` 那幾行拿掉**——`deploy.sh` 的 `git add -A` 會立刻把它們變回
  壞掉的 gitlink。`.claude/` 同理（Claude Code 的 worktree 殘留）。
- **兩個孤兒 CSV**：`jp_japan_universe_yfinance.csv`、`kr_market_yfinance_universe.csv`
  沒有被任何程式碼引用，也不在 rsync 清單裡。應該是別的專案留下的。

## 相關

MBP 的 SSH、PM2 程序表、Cloudflare tunnel 設定記在 `connect-server-skill`，
不要在這裡重複。**注意兩邊已經有落差**：該 skill 的表格寫 port 3002 是
`tunatrade`，但 `server.js` 現在對應的是 `tunapfl`。以程式碼為準。
