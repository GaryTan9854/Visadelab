// Visadelab Portal — zero-dependency static server + local version aggregator
// Replaces `python3 -m http.server 3000`. Runs on MBP under PM2 as "portal".
//
// GET /api/versions — fans out to each app's /api/health on localhost (same
// machine, never touches Cloudflare/Access) and returns { key: {version, build} }.

const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const PORT = 3000;
const ROOT = __dirname;

// card key (data-app in index.html) → local port
const APP_PORTS = {
  tunaspend: 3001,
  tunapfl: 3002,
  tunanote: 3003,
  buddhist: 3004,
  tunatcm: 3006,
  tunawealth: 3007,
  tunatravel: 3008,
  gaglobal: 3010,
  tunabazi: 3011,
  thirteencards: 3013,
  fourcolors: 3014,
  tunaiching: 3015,
  xiyou: 3016,
  sanguo: 3017,
  parasite: 3018,
  '543': 3019,
  histology: 3020,
  fanjian: 3021,
};

const CACHE_MS = 60_000;
let versionsCache = { at: 0, data: null };

async function fetchHealth(port) {
  try {
    const res = await fetch(`http://127.0.0.1:${port}/api/health`, {
      signal: AbortSignal.timeout(2000),
    });
    if (!res.ok) return null;
    const d = await res.json();
    if (!d || !d.version) return null;
    return { version: String(d.version), build: d.build ? String(d.build) : '' };
  } catch {
    return null;
  }
}

async function getVersions() {
  if (versionsCache.data && Date.now() - versionsCache.at < CACHE_MS) {
    return versionsCache.data;
  }
  const keys = Object.keys(APP_PORTS);
  const results = await Promise.all(keys.map((k) => fetchHealth(APP_PORTS[k])));
  const data = {};
  keys.forEach((k, i) => { if (results[i]) data[k] = results[i]; });
  versionsCache = { at: Date.now(), data };
  return data;
}

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.svg': 'image/svg+xml',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
};

function serveStatic(req, res, filePath) {
  let body;
  try {
    body = fs.readFileSync(filePath);
  } catch {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
    return;
  }
  const etag = '"' + crypto.createHash('sha1').update(body).digest('hex').slice(0, 16) + '"';
  if (req.headers['if-none-match'] === etag) {
    res.writeHead(304, { ETag: etag, 'Cache-Control': 'no-cache' });
    res.end();
    return;
  }
  res.writeHead(200, {
    'Content-Type': MIME[path.extname(filePath)] || 'application/octet-stream',
    'Cache-Control': 'no-cache',
    ETag: etag,
  });
  res.end(body);
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');

  if (url.pathname === '/api/versions') {
    const data = await getVersions();
    res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
    res.end(JSON.stringify(data));
    return;
  }

  if (url.pathname === '/api/health') {
    res.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
    res.end(JSON.stringify({ status: 'ok', app: 'portal' }));
    return;
  }

  // static: only files that actually live in this directory, no traversal
  const name = url.pathname === '/' ? 'index.html' : path.basename(url.pathname);
  serveStatic(req, res, path.join(ROOT, name));
});

server.listen(PORT, () => {
  console.log(`portal listening on :${PORT}`);
});
