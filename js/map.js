(function () {
  'use strict';

  function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]);
  }

  const T = { AUD: 'aud', SERVICE: 'service', STAIRS: 'stairs' };
  const NS = 'http://www.w3.org/2000/svg';

  const M = window.KioskMap = {
    floorPlans: [],
    onNavigate: () => {},
    onToast: () => {}
  };

  let root = null;
  let svg = null;
  let viewport = null;
  let roomCard = null;
  let searchInput = null;
  let searchDrop = null;
  let currentPlan = 'uk3';
  let selected = null;
  let route = null;
  let view = { x: 0, y: 0, k: 1 };
  let drag = null;
  let suppressClickUntil = 0;

  const $ = (selector) => root.querySelector(selector);
  const $$ = (selector) => Array.from(root.querySelectorAll(selector));

  const planByKey = key => M.floorPlans.find(plan => plan.key === key);
  const isLk = key => key.startsWith('lk');
  const corpusOf = key => isLk(key) ? 'lk' : 'uk';

  function svgEl(tag, attrs = {}) {
    const node = document.createElementNS(NS, tag);
    Object.entries(attrs).forEach(([key, value]) => node.setAttribute(key, value));
    return node;
  }

  function roomsForPlan(key) {
    const plan = planByKey(key);
    return plan ? (plan.rooms || []) : [];
  }

  M.allRooms = function () {
    return M.floorPlans.flatMap(plan => roomsForPlan(plan.key)
      .filter(room => room.type !== T.STAIRS && room.id !== 'entrance')
      .map(room => ({ plan: plan.key, short: plan.short, room })));
  };

  M.findRoom = function (id) {
    const normalized = id === 'с/з' ? 'sport' : id;
    return M.allRooms().find(item => item.room.id === normalized) || null;
  };

  function applyView() {
    viewport.setAttribute('transform', `translate(${view.x},${view.y}) scale(${view.k})`);
    $('#zoomIn').disabled = view.k >= 3.5;
    $('#zoomOut').disabled = view.k <= 1;
  }

  function roomCenter(room) { return { x: room.x + room.w / 2, y: room.y + room.h / 2 }; }
  function entryPoint(room, from) {
    const cx = room.x + room.w / 2;
    const cy = room.y + room.h / 2;
    const dx = cx - from.x;
    const dy = cy - from.y;
    let tmin = 0;
    let tmax = 1;
    [[room.x, room.x + room.w, dx, from.x], [room.y, room.y + room.h, dy, from.y]].forEach(([min, max, d, s]) => {
      if (d === 0) { if (s < min || s > max) tmax = -1; return; }
      let t1 = (min - s) / d;
      let t2 = (max - s) / d;
      if (t1 > t2) [t1, t2] = [t2, t1];
      tmin = Math.max(tmin, t1);
      tmax = Math.min(tmax, t2);
    });
    if (tmax < tmin || tmax <= 0) return from;
    const t = tmin > 0 ? tmin : 0;
    return { x: Math.round(from.x + dx * t), y: Math.round(from.y + dy * t) };
  }

  function shortName(room) {
    if (room.type === T.STAIRS) return 'лестница';
    if (room.id === 'entrance') return 'главный вход';
    return room.name.replace('Аудитория ', 'ауд. ').replace('Компьютерный класс', 'комп. класс');
  }

  function addLabel(group, room) {
    const center = roomCenter(room);
    if (room.type === T.STAIRS || room.id === 'wc-m' || room.id === 'wc-f') {
      const icon = room.type === T.STAIRS ? '#i-stairs' : `#i-${room.id}`;
      const size = Math.min(58, room.w * 0.58);
      group.appendChild(svgEl('use', {
        href: icon, x: center.x - size / 2, y: center.y - size / 2,
        width: size, height: size, class: 'plan-room__icon'
      }));
      return;
    }

    const label = room.label || room.id;
    const numeric = /^\d/.test(label);
    const main = room.id === 'entrance' ? 'ВХОД' : (numeric ? label : room.name);
    const words = main.split(' ');
    const lines = [];
    if (!numeric && main.length > 12) {
      let line = '';
      words.forEach(word => {
        if ((line + ' ' + word).trim().length > 13 && line) { lines.push(line); line = word; }
        else line = (line + ' ' + word).trim();
      });
      if (line) lines.push(line);
    } else lines.push(main);

    let shown = lines.slice(0, 3);
    const joined = shown.join(' ');
    if (room.w < 76 && joined.length > 3) {
      const vSize = Math.round(Math.max(12, Math.min(18, (room.h - 14) / joined.length * 1.5)));
      const vertical = svgEl('text', {
        x: center.x, y: center.y,
        class: 'plan-room__label',
        'dominant-baseline': 'middle',
        transform: `rotate(-90 ${center.x} ${center.y})`
      });
      vertical.style.fontSize = `${vSize}px`;
      vertical.textContent = joined;
      group.appendChild(vertical);
      return;
    }
    if (room.h < 110 && shown.length > 2) shown = shown.slice(0, 2);
    const maxLen = Math.max(...shown.map(item => item.length));
    const fontSize = Math.round(Math.max(11, Math.min(32, (room.w - 10) / maxLen * 1.5)));
    const lineHeight = Math.round(fontSize * 1.25);
    const text = svgEl('text', {
      x: center.x,
      y: center.y - (shown.length - 1) * lineHeight * 0.5,
      class: 'plan-room__label',
      'dominant-baseline': 'middle'
    });
    text.style.fontSize = `${fontSize}px`;
    shown.forEach((line, index) => {
      const span = svgEl('tspan', { x: center.x, dy: index ? lineHeight : 0 });
      span.textContent = line;
      text.appendChild(span);
    });
    group.appendChild(text);
  }

  function makeRouteGraph() {
    const nodes = new Map();
    const adjacent = new Map();
    M.floorPlans.forEach(plan => (plan.route_nodes || []).forEach(node => {
      nodes.set(node.id, { ...node, plan: plan.key });
      adjacent.set(node.id, new Set());
    }));
    const connect = (a, b) => {
      if (!nodes.has(a) || !nodes.has(b) || a === b) return;
      adjacent.get(a).add(b);
      adjacent.get(b).add(a);
    };
    M.floorPlans.forEach(plan => (plan.route_edges || []).forEach(edge => connect(edge.node_a, edge.node_b)));

    [false, true].forEach(lk => {
      const floors = M.floorPlans.filter(plan => isLk(plan.key) === lk)
        .map(plan => ({ key: plan.key, nodes: (plan.route_nodes || []).filter(node => node.kind === 'stairs') }))
        .filter(item => item.nodes.length);
      for (let index = 1; index < floors.length; index += 1) {
        floors[index - 1].nodes.forEach(a => {
          const nearest = floors[index].nodes.slice().sort((left, right) =>
            ((left.x - a.x) ** 2 + (left.y - a.y) ** 2) - ((right.x - a.x) ** 2 + (right.y - a.y) ** 2)
          )[0];
          if (nearest) connect(a.id, nearest.id);
        });
      }
    });
    const passages = [];
    M.floorPlans.forEach(plan => (plan.route_nodes || [])
      .filter(node => node.kind === 'passage')
      .forEach(node => passages.push(node.id)));
    for (let index = 1; index < passages.length; index += 1) {
      connect(passages[index - 1], passages[index]);
    }
    return { nodes, adjacent };
  }

  function nearestRoomNode(planKey, room, nodes) {
    const center = roomCenter(room);
    const candidates = Array.from(nodes.values()).filter(node => node.plan === planKey);
    const linked = candidates.filter(node => node.room_key === room.id);
    const choices = linked.length ? linked : candidates;
    return choices.sort((a, b) => {
      const distanceA = (a.x - center.x) ** 2 + (a.y - center.y) ** 2;
      const distanceB = (b.x - center.x) ** 2 + (b.y - center.y) ** 2;
      return distanceA - distanceB || a.id - b.id;
    })[0] || null;
  }

  function routeSteps(path, nodes, room) {
    const steps = ['Вход'];
    for (let index = 1; index < path.length; index += 1) {
      const from = nodes.get(path[index - 1]);
      const to = nodes.get(path[index]);
      if (from.plan === to.plan) continue;
      if (from.kind === 'stairs' || to.kind === 'stairs') {
        const label = from.room_key === 'stairs-w' || to.room_key === 'stairs-w' ? 'главная лестница' : 'лестница';
        if (!steps.includes(label)) steps.push(label);
      }
      const targetPlan = planByKey(to.plan);
      steps.push(/^\d/.test(targetPlan.btn) ? `${targetPlan.btn.charAt(0)} этаж${isLk(to.plan) ? ' ЛК' : ''}` : targetPlan.btn);
    }
    steps.push(shortName(room));
    return steps.join(' → ');
  }

  function buildRoute(planKey, room) {
    const base = { plan: planKey, room, path: [], floorKeys: [], steps: '', error: '' };
    const targetPlan = planByKey(planKey);
    if (!targetPlan || !(targetPlan.route_nodes || []).length) {
      return { ...base, error: 'Маршрутная сеть этажа пока не настроена' };
    }
    const graph = makeRouteGraph();
    const start = Array.from(graph.nodes.values()).find(node => node.plan === 'uk1' && node.kind === 'entrance');
    const target = nearestRoomNode(planKey, room, graph.nodes);
    if (!start || !target) return { ...base, error: 'Маршрутная сеть этажа пока не настроена' };

    const previous = new Map([[start.id, null]]);
    const queue = [start.id];
    for (let index = 0; index < queue.length && !previous.has(target.id); index += 1) {
      const id = queue[index];
      graph.adjacent.get(id).forEach(next => {
        if (previous.has(next)) return;
        previous.set(next, id);
        queue.push(next);
      });
    }
    if (!previous.has(target.id)) {
      return { ...base, error: 'Маршрут до помещения не найден. Проверьте связи маршрутной сети.' };
    }
    const path = [];
    let current = target.id;
    while (current !== null) { path.unshift(current); current = previous.get(current); }
    return {
      ...base, path,
      floorKeys: Array.from(new Set(path.map(id => graph.nodes.get(id).plan))),
      steps: routeSteps(path, graph.nodes, room)
    };
  }

  function drawRoute(key, layer) {
    if (!route || route.error || !route.path.length) return;
    const graph = makeRouteGraph();
    let points = [];
    const flush = () => {
      if (points.length > 1) {
        layer.appendChild(svgEl('path', {
          d: points.map((point, index) => `${index ? 'L' : 'M'} ${point.x} ${point.y}`).join(' '),
          class: 'plan-route', 'aria-hidden': 'true'
        }));
      }
      points = [];
    };
    route.path.forEach(id => {
      const node = graph.nodes.get(id);
      if (node.plan !== key) { flush(); return; }
      points.push({ x: node.x, y: node.y });
    });
    if (key === route.plan && points.length) points.push(entryPoint(route.room, points[points.length - 1]));
    flush();
  }

  function renderFloorButtons() {
    const corpus = corpusOf(currentPlan);
    $$('.corpus-button').forEach(button => {
      const active = button.dataset.corpus === corpus;
      button.classList.toggle('is-on', active);
      button.setAttribute('aria-pressed', String(active));
    });
    const floorSwitch = $('#floorSwitch');
    floorSwitch.innerHTML = '';
    M.floorPlans.filter(plan => corpusOf(plan.key) === corpus).forEach(plan => {
      const button = document.createElement('button');
      button.className = 'floor-button';
      button.dataset.floor = plan.key;
      button.textContent = /^\d/.test(plan.btn) ? `${plan.btn.charAt(0)} этаж` : plan.btn;
      button.setAttribute('aria-pressed', String(plan.key === currentPlan));
      if (plan.key === currentPlan) button.classList.add('is-on');
      button.addEventListener('click', () => { drawFloor(plan.key, true); });
      floorSwitch.appendChild(button);
    });
  }

  function drawFloor(key, resetView = false) {
    const corpusChanged = corpusOf(key) !== corpusOf(currentPlan);
    currentPlan = key;
    if (corpusChanged) renderFloorButtons();
    if (resetView) view = { x: 0, y: 0, k: 1 };
    viewport.innerHTML = '';
    const plan = planByKey(key);
    $('#mapPlanTitle').textContent = plan.title.replace(' · ', ' — ').replace(/^(\d) этаж — (.*)$/, '$2 — $1 этаж');
    $$('.floor-button[data-floor]').forEach(button => {
      const active = button.dataset.floor === key;
      button.classList.toggle('is-on', active);
      button.setAttribute('aria-pressed', String(active));
    });

    const layers = {};
    ['underlay', 'walls', 'rooms', 'labels', 'route', 'overlay'].forEach(name => {
      layers[name] = svgEl('g', { id: `layer-${name}` });
      viewport.appendChild(layers[name]);
    });
    if (plan.underlay_path) {
      const scale = Number(plan.underlay_scale) || 1;
      layers.underlay.appendChild(svgEl('image', {
        href: plan.underlay_path,
        x: (1240 - 1240 * scale) / 2, y: (720 - 720 * scale) / 2,
        width: 1240 * scale, height: 720 * scale,
        opacity: plan.underlay_opacity ?? 0.35,
        preserveAspectRatio: 'xMidYMid meet', 'aria-hidden': 'true'
      }));
    }
    const wall = svgEl('rect', { x: 20, y: 20, width: 1200, height: 680, rx: 6, class: 'plan-wall' });
    if (plan.underlay_path) wall.setAttribute('fill', 'none');
    layers.walls.appendChild(wall);
    if (key === 'uk1') {
      layers.walls.appendChild(svgEl('path', {
        d: 'M 30 270 H 290 V 170 H 760 V 30 H 840 V 170 H 1200 V 550 H 290 V 650 H 30 Z',
        fill: 'none',
        class: 'plan-wall'
      }));
    }
    if (key !== 'uk1') {
      layers.walls.appendChild(svgEl('rect', { x: 40, y: 310, width: 1160, height: 120, class: 'plan-corridor' }));
    }

    roomsForPlan(key).forEach(room => {
      const isSelected = selected && selected.plan === key && selected.room.id === room.id;
      const className = `plan-room${room.type === T.SERVICE ? ' plan-room--service' : ''}${room.type === T.STAIRS ? ' plan-room--stairs' : ''}${isSelected ? ' plan-room--selected' : ''}`;
      const group = svgEl('g', {
        class: className, role: 'button', tabindex: '0',
        'aria-label': `${room.name}, ${plan.short}`,
        'aria-pressed': String(Boolean(isSelected))
      });
      group.appendChild(svgEl('rect', { x: room.x, y: room.y, width: room.w, height: room.h, rx: 4, class: 'plan-room__shape' }));
      const labelGroup = svgEl('g', { class: className, 'aria-hidden': 'true' });
      addLabel(labelGroup, room);
      layers.labels.appendChild(labelGroup);
      group.addEventListener('click', event => {
        event.stopPropagation();
        if (Date.now() < suppressClickUntil) return;
        selectRoom(key, room);
      });
      group.addEventListener('keydown', event => {
        if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); selectRoom(key, room); }
      });
      layers.rooms.appendChild(group);
    });

    drawRoute(key, layers.route);
    if (key === 'uk1') {
      const entranceNode = (plan.route_nodes || []).find(node => node.kind === 'entrance');
      const entranceRoom = roomsForPlan(key).find(room => room.id === 'entrance');
      const point = entranceNode || (entranceRoom ? roomCenter(entranceRoom) : null);
      if (point) {
        layers.overlay.appendChild(svgEl('circle', { cx: point.x, cy: point.y, r: 14, class: 'plan-you' }));
        const label = svgEl('text', { x: point.x, y: point.y + 37, class: 'plan-you-label' });
        label.textContent = 'ВЫ ЗДЕСЬ';
        layers.overlay.appendChild(label);
      }
    }
    applyView();
  }

  function renderRoomCard() {
    if (!selected) {
      roomCard.innerHTML = '<p class="room-card__empty">Найдите аудиторию через поиск<br>или коснитесь помещения на схеме</p>';
      return;
    }
    const { room, plan } = selected;
    const planData = planByKey(plan);
    const type = room.type === T.AUD ? 'Учебная аудитория' : room.type === T.STAIRS ? 'Лестничная клетка' : 'Служба / помещение';
    const routeMatches = route && route.plan === plan && route.room.id === room.id;
    let routeHtml = '';
    if (routeMatches && route.error) {
      routeHtml = `<p class="room-card__route">${escapeHtml(route.error)}</p>`;
    } else if (routeMatches) {
      routeHtml = `<p class="room-card__route">${escapeHtml(route.steps)}</p>`;
      if (route.floorKeys.length > 1) {
        routeHtml += '<div class="room-card__buttons">' + route.floorKeys.map(key => {
          const floor = planByKey(key);
          return `<button class="btn ${key === currentPlan ? 'btn--primary' : 'btn--ghost'}" data-route-floor="${escapeHtml(key)}">${escapeHtml(floor.btn)}</button>`;
        }).join('') + '</div>';
      }
    }
    roomCard.innerHTML = `
      <div class="room-card__num">${escapeHtml(room.id === 'entrance' ? 'ВХОД' : (room.label || room.id))}</div>
      <div class="room-card__name">${escapeHtml(room.name)}</div>
      <div class="room-card__type">${type} · ${escapeHtml(planData.short)}</div>
      <div class="room-card__buttons">
        <button class="btn btn--primary" id="routeButton">Маршрут от входа</button>
        <button class="btn btn--ghost" id="clearRoomButton">Сбросить</button>
      </div>
      ${routeHtml}`;
    $('#routeButton').addEventListener('click', () => {
      route = buildRoute(plan, room);
      drawFloor(currentPlan);
      renderRoomCard();
      M.onToast(route.error || 'Маршрут построен от главного входа');
    });
    $('#clearRoomButton').addEventListener('click', clearRoom);
    Array.from(roomCard.querySelectorAll('[data-route-floor]')).forEach(button => {
      button.addEventListener('click', () => {
        drawFloor(button.dataset.routeFloor, true);
        renderRoomCard();
      });
    });
  }

  function clearRoom() {
    selected = null;
    route = null;
    searchInput.value = '';
    drawFloor(currentPlan);
    renderRoomCard();
  }

  function selectRoom(plan, room) {
    if (route && (route.plan !== plan || route.room.id !== room.id)) route = null;
    selected = { plan, room };
    if (currentPlan !== plan) {
      drawFloor(plan, true);
    } else {
      drawFloor(plan);
    }
    renderRoomCard();
    $('#mapHint').classList.add('is-off');
  }

  M.goToRoom = function (id) {
    const found = M.findRoom(id);
    if (!found) { M.onToast('Это помещение пока не отмечено на схеме'); return false; }
    M.onNavigate('map');
    searchInput.value = found.room.label || found.room.id;
    selectRoom(found.plan, found.room);
    return true;
  };

  function closeSearch() { searchDrop.hidden = true; searchInput.setAttribute('aria-expanded', 'false'); }
  function renderSearch() {
    const query = searchInput.value.trim().toLocaleLowerCase('ru');
    if (!query) { closeSearch(); return; }
    const found = M.allRooms().filter(item =>
      item.room.id.toLocaleLowerCase('ru').includes(query) || (item.room.label || '').toLocaleLowerCase('ru').includes(query) || item.room.name.toLocaleLowerCase('ru').includes(query)
    ).slice(0, 8);
    searchDrop.innerHTML = found.length ? found.map(item => `
      <button class="autocomplete__item" role="option" data-plan="${escapeHtml(item.plan)}" data-room="${escapeHtml(item.room.id)}">
        <span>${escapeHtml(item.room.name)}</span><small>${escapeHtml(item.short)}</small>
      </button>`).join('') : '<p class="autocomplete__empty">Ничего не найдено. Проверьте номер или название.</p>';
    searchDrop.hidden = false;
    searchInput.setAttribute('aria-expanded', 'true');
    $$('.autocomplete__item', searchDrop).forEach(button => {
      const choose = () => {
        const room = roomsForPlan(button.dataset.plan).find(item => item.id === button.dataset.room);
        searchInput.value = room.label || room.id;
        closeSearch();
        selectRoom(button.dataset.plan, room);
      };
      button.addEventListener('pointerdown', event => { event.preventDefault(); choose(); });
      button.addEventListener('click', choose);
    });
  }

  function svgPoint(clientX, clientY) {
    const rect = svg.getBoundingClientRect();
    const scale = Math.min(rect.width / 1240, rect.height / 720);
    const offsetX = (rect.width - 1240 * scale) / 2;
    const offsetY = (rect.height - 720 * scale) / 2;
    return { x: (clientX - rect.left - offsetX) / scale, y: (clientY - rect.top - offsetY) / scale };
  }

  function zoomBy(factor, clientX, clientY) {
    const next = Math.min(3.5, Math.max(1, view.k * factor));
    if (next === view.k) return;
    const rect = svg.getBoundingClientRect();
    const point = svgPoint(clientX ?? rect.left + rect.width / 2, clientY ?? rect.top + rect.height / 2);
    view.x = point.x - (point.x - view.x) * (next / view.k);
    view.y = point.y - (point.y - view.y) * (next / view.k);
    view.k = next;
    applyView();
  }

  M.init = function (options) {
    root = options.root;
    M.floorPlans = options.floorPlans || [];
    M.onNavigate = options.onNavigate || (() => {});
    M.onToast = options.onToast || (() => {});

    svg = $('#mapSvg');
    viewport = $('#mapViewport');
    roomCard = $('#roomCard');
    searchInput = $('#mapSearch');
    searchDrop = $('#mapSearchDrop');

    const corpusSwitch = $('#corpusSwitch');
    if (corpusSwitch) {
      corpusSwitch.innerHTML = '';
      [['uk', 'Учебный корпус'], ['lk', 'Лабораторный корпус']].forEach(([corpus, label]) => {
      const button = document.createElement('button');
      button.className = 'floor-button corpus-button';
      button.dataset.corpus = corpus;
      button.textContent = label;
      button.setAttribute('aria-pressed', 'false');
      button.addEventListener('click', () => {
        if (corpusOf(currentPlan) === corpus) return;
        const first = M.floorPlans.find(plan => corpusOf(plan.key) === corpus);
        if (first) drawFloor(first.key, true);
      });
      corpusSwitch.appendChild(button);
      });
    }
    renderFloorButtons();
    searchInput.addEventListener('input', renderSearch);
    searchInput.addEventListener('focus', () => { if (searchInput.value) renderSearch(); });
    searchInput.addEventListener('keydown', event => {
      if (event.key === 'Escape') closeSearch();
      if (event.key === 'ArrowDown' && !searchDrop.hidden) {
        event.preventDefault();
        root.querySelector('.autocomplete__item', searchDrop)?.focus();
      }
    });
    searchDrop.addEventListener('keydown', event => {
      const items = $$('.autocomplete__item', searchDrop);
      const index = items.indexOf(document.activeElement);
      if (event.key === 'ArrowDown') { event.preventDefault(); items[Math.min(index + 1, items.length - 1)]?.focus(); }
      if (event.key === 'ArrowUp') { event.preventDefault(); index <= 0 ? searchInput.focus() : items[index - 1]?.focus(); }
      if (event.key === 'Escape') { closeSearch(); searchInput.focus(); }
    });
    document.addEventListener('click', event => { if (!event.target.closest('.map-search-wrap') && !event.target.closest('.vkb')) closeSearch(); });

    $('#zoomIn').addEventListener('click', () => zoomBy(1.35));
    $('#zoomOut').addEventListener('click', () => zoomBy(1 / 1.35));
    $('#zoomReset').addEventListener('click', () => { view = { x: 0, y: 0, k: 1 }; applyView(); });
    svg.addEventListener('wheel', event => {
      event.preventDefault();
      zoomBy(event.deltaY < 0 ? 1.15 : 1 / 1.15, event.clientX, event.clientY);
    }, { passive: false });
    svg.addEventListener('pointerdown', event => {
      drag = { x: event.clientX, y: event.clientY, vx: view.x, vy: view.y, moved: false };
      svg.setPointerCapture(event.pointerId);
      svg.classList.add('is-drag');
    });
    svg.addEventListener('pointermove', event => {
      if (!drag) return;
      const rect = svg.getBoundingClientRect();
      const scale = Math.min(rect.width / 1240, rect.height / 720);
      if (Math.abs(event.clientX - drag.x) + Math.abs(event.clientY - drag.y) > 8) drag.moved = true;
      view.x = drag.vx + (event.clientX - drag.x) / scale;
      view.y = drag.vy + (event.clientY - drag.y) / scale;
      applyView();
    });
    const endDrag = () => {
      if (drag?.moved) suppressClickUntil = Date.now() + 180;
      drag = null;
      svg.classList.remove('is-drag');
    };
    svg.addEventListener('pointerup', endDrag);
    svg.addEventListener('pointercancel', endDrag);

    if (!planByKey(currentPlan) && M.floorPlans.length) currentPlan = M.floorPlans[0].key;
    drawFloor(currentPlan, true);
    renderRoomCard();
  };
})();
