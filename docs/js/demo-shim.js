(function () {
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
