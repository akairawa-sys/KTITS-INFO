'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..', '..');
const DOCS = path.join(ROOT, 'docs');
const API = (process.env.KTITS_DEMO_API || 'http://ktits-info').replace(/\/+$/, '');

function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const from = path.join(src, entry.name);
    const to = path.join(dest, entry.name);
    if (entry.isDirectory()) copyDir(from, to);
    else fs.copyFileSync(from, to);
  }
}

async function main() {
  const response = await fetch(API + '/api/index.php?action=bootstrap');
  const data = await response.json();
  if (!data.ok) throw new Error('API вернул ошибку: ' + (data.error || response.status));

  for (const dir of ['css', 'js', 'assets', 'uploads']) {
    copyDir(path.join(ROOT, dir), path.join(DOCS, dir));
  }

  const stamp = new Date().toLocaleString('ru-RU');
  const pad = value => String(value).padStart(2, '0');
  const stampKey = `${new Date().getFullYear()}${pad(new Date().getMonth() + 1)}${pad(new Date().getDate())}-${pad(new Date().getHours())}${pad(new Date().getMinutes())}${pad(new Date().getSeconds())}`;
  fs.writeFileSync(
    path.join(DOCS, 'js', 'demo-data.js'),
    'window.__STATIC_BOOTSTRAP__=' + JSON.stringify(data) + ';\n'
  );

  const shim = `(function () {
  var data = window.__STATIC_BOOTSTRAP__;
  if (!data) return;
  var nativeFetch = window.fetch.bind(window);
  window.fetch = function (input, init) {
    var url = typeof input === 'string' ? input : String((input && input.url) || '');
    if (url.indexOf('api/index.php') === -1) return nativeFetch(input, init);
    if (url.indexOf('action=bootstrap') !== -1) {
      return Promise.resolve(new Response(JSON.stringify(data), { status: 200, headers: { 'Content-Type': 'application/json' } }));
    }
    return Promise.resolve(new Response(JSON.stringify({ ok: false, error: 'Демо-версия работает без сервера: сохранение недоступно.' }), { status: 200, headers: { 'Content-Type': 'application/json' } }));
  };
})();
`;
  fs.writeFileSync(path.join(DOCS, 'js', 'demo-shim.js'), shim);

  const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');
  const inject = '  <style>.demo-badge{position:fixed;right:14px;bottom:14px;z-index:9999;padding:8px 16px;'
    + 'border-radius:999px;background:#1d2b53;color:#fff;font:600 13px/1.2 system-ui,sans-serif;opacity:.9;'
    + 'box-shadow:0 4px 16px rgba(0,0,0,.25);pointer-events:none}</style>\n'
    + `  <script src="js/demo-data.js?v=${stampKey}"></script>\n`
    + '  <script src="js/demo-shim.js"></script>\n'
    + `  <div class="demo-badge">Демо-версия · данные на ${stamp}</div>\n`;
  const marker = '<script type="module" src="js/dist/app.js';
  const at = html.indexOf(marker);
  if (at === -1) throw new Error('Не найден тег подключения app.js в index.html');
  fs.writeFileSync(path.join(DOCS, 'index.html'), html.slice(0, at) + inject + html.slice(at));

  console.log('Демо собрано в docs/ · данные от ' + stamp);
}

main().catch(error => { console.error(error.message); process.exit(1); });
