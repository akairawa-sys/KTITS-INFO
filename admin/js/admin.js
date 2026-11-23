// Логика входа и работы админки
(function () {
  'use strict';

  const $ = (selector, root) => (root || document).querySelector(selector);
  const $$ = (selector, root) => Array.from((root || document).querySelectorAll(selector));
  const API = '../api/index.php';
  const ROLE_NAMES = { admin: 'Администратор', schedule: 'Редактор расписания', content: 'Редактор контента' };
  let csrfToken = '';
  let currentUser = null;
  let toastTimer;

  function toast(message, duration = 3600) {
    const el = $('#toast');
    el.textContent = message;
    el.hidden = false;
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => { el.hidden = true; }, duration);
  }

  function escapeHtml(value) {
    return String(value ?? '').replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]);
  }
  const escapeAttr = escapeHtml;
  const asset = path => path ? '../' + String(path).replace(/^\/+/, '') : '';
  const initials = name => String(name || '—').trim().split(/\s+/).slice(0, 2).map(part => part[0]).join('').toUpperCase();

  async function api(action, options = {}) {
    const method = options.method || 'GET';
    const headers = { Accept: 'application/json', ...(options.headers || {}) };
    let body = options.body;
    if (body && !(body instanceof FormData)) {
      headers['Content-Type'] = 'application/json';
      body = JSON.stringify(body);
    }
    if (method !== 'GET' && csrfToken) headers['X-CSRF-Token'] = csrfToken;
    const response = await fetch(`${API}?action=${encodeURIComponent(action)}${options.query || ''}`, {
      method, headers, body, credentials: 'same-origin'
    });
    const text = await response.text();
    let data;
    try { data = JSON.parse(text); } catch { data = { ok: false, error: 'Сервер вернул некорректный ответ.' }; }
    if (response.status === 401 && !options.skipAuthRedirect && $('#authForm') === null) {
      window.location.href = 'index.html';
      throw new Error('Требуется вход.');
    }
    if (!response.ok || !data.ok) {
      const error = new Error(data.error || 'Ошибка запроса.');
      error.details = data.details || [];
      throw error;
    }
    return data;
  }

  function openModal(id) {
    const backdrop = $('#' + id);
    backdrop.hidden = false;
    const first = backdrop.querySelector('input:not([type="hidden"]), select, textarea, button');
    if (first) first.focus();
  }
  function closeModal(backdrop) { backdrop.hidden = true; }
  $$('.modal-backdrop').forEach(backdrop => {
    backdrop.addEventListener('click', event => { if (event.target === backdrop) closeModal(backdrop); });
    $$('[data-close-modal]', backdrop).forEach(button => button.addEventListener('click', () => closeModal(backdrop)));
  });
  document.addEventListener('keydown', event => {
    if (event.key !== 'Escape') return;
    const opened = $$('.modal-backdrop').find(modal => !modal.hidden);
    if (opened) closeModal(opened);
  });

  let confirmAction = null;
  function askConfirm(text, onYes) {
    $('#confirmText').textContent = text;
    confirmAction = onYes;
    openModal('modalConfirm');
  }
  if ($('#confirmYes')) $('#confirmYes').addEventListener('click', () => {
    if (confirmAction) confirmAction();
    confirmAction = null;
    closeModal($('#modalConfirm'));
  });

  function setError(input, message) {
    const wrap = input.closest('.form-field');
    const slot = wrap ? wrap.querySelector(`[data-error-for="${input.id}"]`) : null;
    if (wrap) wrap.classList.toggle('has-error', Boolean(message));
    if (slot) slot.textContent = message || '';
    return !message;
  }

  // АВТОРИЗАЦИЯ
  const authForm = $('#authForm');
  if (authForm) {
    const password = $('#authPassword');
    $('#togglePassword').addEventListener('click', () => {
      const show = password.type === 'password';
      password.type = show ? 'text' : 'password';
      $('#togglePassword').setAttribute('aria-label', show ? 'Скрыть пароль' : 'Показать пароль');
    });
    authForm.addEventListener('submit', async event => {
      event.preventDefault();
      const login = $('#authLogin');
      if (!setError(login, login.value.trim() ? '' : 'Введите логин')) return;
      if (!setError(password, password.value.length >= 4 ? '' : 'Минимум 4 символа')) return;
      const submit = authForm.querySelector('button[type="submit"]');
      submit.disabled = true;
      submit.textContent = 'Вход…';
      try {
        const data = await api('login', {
          method: 'POST',
          body: { login: login.value.trim(), password: password.value, remember: $('#authRemember').checked },
          skipAuthRedirect: true
        });
        csrfToken = data.csrf_token;
        toast('Вход выполнен. Открываю панель…');
        setTimeout(() => { window.location.href = 'panel.html'; }, 350);
      } catch (error) {
        setError(password, error.message);
        toast(error.message);
      } finally {
        submit.disabled = false;
        submit.textContent = 'Войти';
      }
    });
    return;
  }

  // КАРКАС ПАНЕЛИ
  const SECTION_TITLES = {
    schedule: 'Расписание занятий', practice: 'Практика', bells: 'Расписание звонков', teachers: 'Преподаватели',
    news: 'Новости', events: 'Афиша событий', map: 'Карта этажей', roles: 'Пользователи и роли'
  };
  const loaders = {};

  function closeSidebar() {
    document.body.classList.remove('sidebar-open');
    $('#sidebarOverlay').hidden = true;
    $('#sidebarToggle').setAttribute('aria-expanded', 'false');
  }
  $('#sidebarToggle').addEventListener('click', () => {
    const open = !document.body.classList.contains('sidebar-open');
    document.body.classList.toggle('sidebar-open', open);
    $('#sidebarOverlay').hidden = !open;
    $('#sidebarToggle').setAttribute('aria-expanded', String(open));
  });
  $('#sidebarOverlay').addEventListener('click', closeSidebar);

  async function showSection(name) {
    const button = $(`.nav-item[data-section="${name}"]`);
    if (!button || button.hidden) return;
    $$('.nav-item[data-section]').forEach(item => item.classList.toggle('is-on', item === button));
    $$('.section').forEach(section => section.classList.toggle('is-active', section.id === 'section-' + name));
    $('#topbarTitle').textContent = SECTION_TITLES[name];
    closeSidebar();
    window.scrollTo({ top: 0, behavior: 'smooth' });
    if (loaders[name]) await loaders[name]();
  }
  $$('.nav-item[data-section]').forEach(button => button.addEventListener('click', () => {
    showSection(button.dataset.section).catch(error => toast(error.message));
  }));

  $('#logoutBtn').addEventListener('click', async () => {
    try { await api('logout', { method: 'POST' }); } catch (error) { console.warn(error); }
    window.location.href = 'index.html';
  });

  // Расписание занятий
  let schedRows = [];
  let schedVersion = '';
  let allBells = [];

  function markSchedDirty() {
    $('#schedState').textContent = 'Есть несохранённые изменения';
    $('#schedState').className = 'badge badge--warn';
  }
  function markSchedSaved(message = 'Синхронизировано с киоском') {
    $('#schedState').textContent = message;
    $('#schedState').className = 'badge badge--ok';
  }
  function schedDayType() {
    return Number($('#schedDay').value) === 6 ? 'sat' : 'week';
  }
  function activeBell(dayType, pairNumber) {
    return allBells.find(row => row.day_type === dayType && row.is_active && row.pair_number === pairNumber);
  }

  function renderSchedule() {
    const body = $('#schedBody');
    body.innerHTML = '';
    if (!schedRows.length) {
      body.innerHTML = '<tr><td colspan="7"><div class="empty"><p class="empty__title">На этот день занятий нет</p><p>Добавьте пару вручную или импортируйте файл.</p></div></td></tr>';
      return;
    }
    const dayType = schedDayType();
    schedRows.forEach((row, index) => {
      const pairNo = Number(row.pair_number) || index + 1;
      const bell = activeBell(dayType, pairNo);
      const start = row.start ?? bell?.start ?? '';
      const end = row.end ?? bell?.end ?? '';
      const tr = document.createElement('tr');
      if (row.is_cancelled) tr.classList.add('is-cancelled');
      tr.innerHTML = `
        <td class="num"><input type="number" class="cell-input cell-input--num" data-f="pair_number" min="1" max="8" step="1" value="${pairNo}" aria-label="Номер пары, строка ${index + 1}"></td>
        <td>${bell
          ? `<div class="time-pair"><input type="time" class="cell-input" data-f="start" value="${escapeAttr(start)}" aria-label="Начало пары ${pairNo}"><input type="time" class="cell-input" data-f="end" value="${escapeAttr(end)}" aria-label="Конец пары ${pairNo}"></div>`
          : '<span class="cell-sub" title="Для этого номера пары нет активного расписания звонков">—</span>'}</td>
        <td><input class="cell-input cell-input--wide" data-f="subject" value="${escapeAttr(row.subject)}" aria-label="Предмет, пара ${pairNo}"></td>
        <td><input class="cell-input cell-input--wide" data-f="teacher" value="${escapeAttr(row.teacher)}" aria-label="Преподаватель, пара ${pairNo}"></td>
        <td><input class="cell-input" data-f="room" style="width:96px" value="${escapeAttr(row.room)}" aria-label="Аудитория, пара ${pairNo}"></td>
        <td>${row.is_cancelled ? '<span class="badge badge--error">Отменена</span>' : '<span class="badge badge--ok">По плану</span>'}</td>
        <td class="cell-actions">
          <button class="icon-btn" data-act="up" aria-label="Поднять пару выше" ${index === 0 ? 'disabled' : ''}><svg class="icon"><use href="#i-up"/></svg></button>
          <button class="icon-btn" data-act="down" aria-label="Опустить пару ниже" ${index === schedRows.length - 1 ? 'disabled' : ''}><svg class="icon"><use href="#i-down"/></svg></button>
          <button class="icon-btn" data-act="cancel" aria-label="${row.is_cancelled ? 'Вернуть пару' : 'Отменить пару'}"><svg class="icon"><use href="#${row.is_cancelled ? 'i-restore' : 'i-ban'}"/></svg></button>
          <button class="icon-btn icon-btn--danger" data-act="del" aria-label="Удалить пару"><svg class="icon"><use href="#i-trash"/></svg></button>
        </td>`;
      body.appendChild(tr);
    });
  }

  async function ensureBells() {
    if (allBells.length) return;
    const data = await api('admin/bells');
    allBells = data.rows;
  }

  async function loadSchedule() {
    if (!$('#schedGroup').value) return;
    $('#schedState').textContent = 'Загрузка…';
    $('#schedState').className = 'badge badge--muted';
    await ensureBells();
    const data = await api('admin/schedule', { query: `&group_id=${encodeURIComponent($('#schedGroup').value)}&day=${encodeURIComponent($('#schedDay').value)}` });
    schedRows = data.rows;
    schedVersion = data.version;
    renderSchedule();
    markSchedSaved();
  }

  async function loadGroups() {
    const data = await api('admin/groups');
    const groups = data.groups;
    $('#schedGroup').innerHTML = groups.map(group => `<option value="${group.id}">${escapeHtml(group.code)} · ${group.course} курс</option>`).join('');
    const days = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота'];
    $('#schedDay').innerHTML = days.map((day, index) => `<option value="${index + 1}">${day}</option>`).join('');
    await loadSchedule();
  }

  $('#schedBody').addEventListener('input', event => {
    const input = event.target.closest('input[data-f]');
    if (!input) return;
    const index = Array.from($('#schedBody').children).indexOf(input.closest('tr'));
    schedRows[index][input.dataset.f] = input.value;
    markSchedDirty();
  });
  $('#schedBody').addEventListener('change', event => {
    const input = event.target.closest('input[data-f="pair_number"]');
    if (!input) return;
    const index = Array.from($('#schedBody').children).indexOf(input.closest('tr'));
    const value = Number(input.value);
    if (!Number.isInteger(value) || value < 1 || value > 8) {
      toast('Номер пары должен быть от 1 до 8.');
      renderSchedule();
      return;
    }
    schedRows[index].pair_number = value;
    delete schedRows[index].start;
    delete schedRows[index].end;
    schedRows.sort((a, b) => (Number(a.pair_number) || 0) - (Number(b.pair_number) || 0));
    renderSchedule();
    markSchedDirty();
  });
  $('#schedBody').addEventListener('click', event => {
    const button = event.target.closest('button[data-act]');
    if (!button) return;
    const index = Array.from($('#schedBody').children).indexOf(button.closest('tr'));
    const action = button.dataset.act;
    if (action === 'up' && index > 0) [schedRows[index - 1], schedRows[index]] = [schedRows[index], schedRows[index - 1]];
    else if (action === 'down' && index < schedRows.length - 1) [schedRows[index + 1], schedRows[index]] = [schedRows[index], schedRows[index + 1]];
    else if (action === 'cancel') schedRows[index].is_cancelled = !schedRows[index].is_cancelled;
    else if (action === 'del') {
      askConfirm(`Удалить пару №${schedRows[index].pair_number ?? index + 1} «${schedRows[index].subject}»?`, () => {
        schedRows.splice(index, 1); renderSchedule(); markSchedDirty();
      });
      return;
    } else return;
    renderSchedule(); markSchedDirty();
  });
  $('#schedAddRow').addEventListener('click', () => {
    if (schedRows.length >= 8) return toast('Больше 8 пар в день быть не может.');
    const nextPair = Math.max(0, ...schedRows.map(row => Number(row.pair_number) || 0)) + 1;
    schedRows.push({ pair_number: nextPair, subject: 'Новая пара', teacher: '', room: '', is_cancelled: false });
    renderSchedule(); markSchedDirty();
    $('#schedBody tr:last-child input')?.focus();
  });
  $('#schedSave').addEventListener('click', async () => {
    if (schedRows.some(row => !row.subject.trim())) return toast('У каждой пары должен быть указан предмет.');
    for (const row of schedRows) {
      const pairNo = Number(row.pair_number);
      if (!Number.isInteger(pairNo) || pairNo < 1 || pairNo > 8) return toast('Номер пары должен быть от 1 до 8.');
    }
    const dayType = schedDayType();
    const timeByPair = new Map();
    for (const row of schedRows) {
      const pairNo = Number(row.pair_number);
      const bell = activeBell(dayType, pairNo);
      const start = row.start ?? bell?.start;
      const end = row.end ?? bell?.end;
      if (!start || !end) continue;
      const prev = timeByPair.get(pairNo);
      if (prev && (prev.start !== start || prev.end !== end)) return toast(`У пары №${pairNo} в разных строках указано разное время.`);
      timeByPair.set(pairNo, { start, end });
    }
    const button = $('#schedSave'); button.disabled = true;
    try {
      const rows = schedRows.map(row => ({
        pair_number: Number(row.pair_number),
        subject: row.subject, teacher: row.teacher, room: row.room,
        is_cancelled: row.is_cancelled,
      }));
      const data = await api('admin/schedule', { method: 'PUT', body: { group_id: Number($('#schedGroup').value), day: Number($('#schedDay').value), rows, version: schedVersion } });
      const bellUpdates = new Map();
      schedRows.forEach(row => {
        const bell = activeBell(dayType, Number(row.pair_number));
        if (!bell) return;
        const start = row.start ?? bell.start;
        const end = row.end ?? bell.end;
        if (start !== bell.start || end !== bell.end) bellUpdates.set(bell.id, { id: bell.id, start, end });
      });
      for (const update of bellUpdates.values()) {
        await api('admin/bells/time', { method: 'PUT', body: update });
      }
      if (bellUpdates.size) { allBells = []; await ensureBells(); }
      markSchedSaved('Сохранено · только что');
      toast(bellUpdates.size ? `${data.message} Время звонков обновлено.` : data.message);
      await loadSchedule();
    } catch (error) {
      toast(error.message, 6500);
    } finally { button.disabled = false; }
  });
  $('#schedReset').addEventListener('click', () => loadSchedule().then(() => toast('Загружена версия из базы данных.')).catch(error => toast(error.message)));
  $('#schedGroup').addEventListener('change', () => loadSchedule().catch(error => toast(error.message)));
  $('#schedDay').addEventListener('change', () => loadSchedule().catch(error => toast(error.message)));
  $('#schedTemplateBtn').addEventListener('click', () => { window.location.href = `${API}?action=admin/schedule/template`; });


  // Импорт XLSX/CSV
  let scheduleFile = null;

  function humanSize(bytes) {
    if (bytes < 1024) return `${bytes} Б`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} КБ`;
    return `${(bytes / 1024 / 1024).toFixed(1)} МБ`;
  }

  function renderScheduleFile() {
    const info = $('#schedFileInfo');
    if (!scheduleFile) { info.innerHTML = ''; return; }
    info.innerHTML = `<div class="file-preview">
      <svg class="icon"><use href="#i-file"/></svg>
      <div><div class="file-preview__name">${escapeHtml(scheduleFile.name)}</div>
      <div class="file-preview__meta">${humanSize(scheduleFile.size)} · готов к проверке и импорту</div></div>
      <div class="file-preview__actions">
        <button type="button" class="btn btn--primary btn--sm" id="schedImportNow">Импортировать</button>
        <button type="button" class="icon-btn" id="schedFileClear" aria-label="Убрать файл"><svg class="icon"><use href="#i-close"/></svg></button>
      </div>
    </div>`;
    $('#schedFileClear').addEventListener('click', () => {
      scheduleFile = null; $('#schedFile').value = ''; renderScheduleFile();
    });
    $('#schedImportNow').addEventListener('click', importSchedule);
  }

  function selectScheduleFile(file) {
    if (!file) return;
    if (!/\.(xlsx|xls|csv)$/i.test(file.name)) return toast('Выберите файл .xlsx или .csv.');
    if (file.size > 10 * 1024 * 1024) return toast('Файл расписания не должен превышать 10 МБ.');
    scheduleFile = file;
    renderScheduleFile();
  }

  async function importSchedule() {
    if (!scheduleFile) return;
    const button = $('#schedImportNow');
    button.disabled = true; button.textContent = 'Импорт…';
    const form = new FormData(); form.append('file', scheduleFile);
    try {
      const data = await api('admin/schedule/import', { method: 'POST', body: form });
      toast(data.message, 6500);
      scheduleFile = null; $('#schedFile').value = ''; renderScheduleFile();
      await loadSchedule();
    } catch (error) {
      toast(error.message, 6500);
      if (error.details.length) {
        $('#schedFileInfo').insertAdjacentHTML('beforeend', `<div class="import-errors"><b>Исправьте строки файла:</b><ul>${error.details.map(item => `<li>${escapeHtml(item)}</li>`).join('')}</ul></div>`);
      }
    } finally {
      if (button) { button.disabled = false; button.textContent = 'Импортировать'; }
    }
  }

  $('#schedDrop').addEventListener('click', () => $('#schedFile').click());
  $('#schedDrop').addEventListener('keydown', event => {
    if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); $('#schedFile').click(); }
  });
  $('#schedFile').addEventListener('change', event => selectScheduleFile(event.target.files[0]));
  ['dragenter', 'dragover'].forEach(type => $('#schedDrop').addEventListener(type, event => {
    event.preventDefault(); $('#schedDrop').classList.add('is-drag');
  }));
  ['dragleave', 'drop'].forEach(type => $('#schedDrop').addEventListener(type, event => {
    event.preventDefault(); $('#schedDrop').classList.remove('is-drag');
  }));
  $('#schedDrop').addEventListener('drop', event => selectScheduleFile(event.dataTransfer.files[0]));

  // Расписание звонков
  let bellsDay = 'week';
  let bellsShort = false;
  let bellRows = [];

  function profileRows(day = bellsDay, short = bellsShort) {
    return allBells.filter(row => row.day_type === day && row.is_short === short)
      .sort((a, b) => a.pair_number - b.pair_number)
      .map(row => ({ start: row.start, end: row.end, break_text: row.break_text }));
  }

  function renderBellRows() {
    const body = $('#bellsBody');
    if (!bellRows.length) {
      body.innerHTML = '<tr><td colspan="5"><div class="empty"><p class="empty__title">Профиль пока пуст</p><p>Добавьте первую пару и сохраните расписание.</p></div></td></tr>';
      return;
    }
    body.innerHTML = bellRows.map((row, index) => `<tr>
      <td class="num">${index + 1}</td>
      <td><input class="cell-input" type="time" data-f="start" value="${escapeAttr(row.start)}" aria-label="Начало пары ${index + 1}"></td>
      <td><input class="cell-input" type="time" data-f="end" value="${escapeAttr(row.end)}" aria-label="Конец пары ${index + 1}"></td>
      <td><input class="cell-input cell-input--wide" data-f="break_text" value="${escapeAttr(row.break_text)}" aria-label="Перемена после пары ${index + 1}" placeholder="10 мин"></td>
      <td class="cell-actions"><button class="icon-btn icon-btn--danger" data-bell-del="${index}" aria-label="Удалить пару ${index + 1}"><svg class="icon"><use href="#i-trash"/></svg></button></td>
    </tr>`).join('');
  }

  function renderBells() {
    bellRows = profileRows();
    $('#bellsShort').checked = bellsShort;
    $('#bellsShortHint').hidden = !bellsShort;
    $$('[data-bells]').forEach(button => {
      const active = button.dataset.bells === bellsDay;
      button.classList.toggle('is-on', active);
      button.setAttribute('aria-selected', String(active));
    });
    renderBellRows();
  }

  async function loadBells() {
    const data = await api('admin/bells');
    allBells = data.rows;
    const active = allBells.find(row => row.day_type === bellsDay && row.is_active);
    bellsShort = active ? active.is_short : false;
    renderBells();
  }

  $$('[data-bells]').forEach(button => button.addEventListener('click', () => {
    bellsDay = button.dataset.bells;
    const active = allBells.find(row => row.day_type === bellsDay && row.is_active);
    bellsShort = active ? active.is_short : false;
    renderBells();
  }));
  $('#bellsShort').addEventListener('change', event => { bellsShort = event.target.checked; renderBells(); });
  $('#bellsBody').addEventListener('input', event => {
    const input = event.target.closest('input[data-f]'); if (!input) return;
    const row = input.closest('tr');
    const index = Array.from($('#bellsBody').children).indexOf(row);
    if (bellRows[index]) bellRows[index][input.dataset.f] = input.value;
  });
  $('#bellsBody').addEventListener('click', event => {
    const button = event.target.closest('[data-bell-del]'); if (!button) return;
    bellRows.splice(Number(button.dataset.bellDel), 1);
    renderBellRows();
  });
  $('#bellsAddRow').addEventListener('click', () => {
    if (bellRows.length >= 8) return toast('Больше 8 пар в день быть не может.');
    const previous = bellRows[bellRows.length - 1];
    bellRows.push({ start: previous ? previous.end : '08:00', end: previous ? previous.end : '09:30', break_text: '10 мин' });
    renderBellRows();
  });
  $('#bellsDefault').addEventListener('click', () => {
    const defaults = bellsDay === 'week'
      ? [['08:00','09:30','10 мин'],['09:40','11:10','40 мин'],['11:50','13:20','20 мин'],['13:40','15:10','10 мин'],['15:20','16:50','10 мин'],['17:00','18:30','10 мин'],['18:40','20:10','']]
      : [['08:00','09:30','10 мин'],['09:40','11:10','20 мин'],['11:30','13:00','10 мин'],['13:10','14:40','10 мин'],['14:50','16:20','10 мин'],['16:30','18:00','']];
    bellRows = defaults.map(row => ({ start: row[0], end: row[1], break_text: row[2] }));
    if (bellsShort) bellRows = bellRows.map((row, index) => {
      const startMinutes = 8 * 60 + index * 35;
      const time = minutes => `${String(Math.floor(minutes / 60)).padStart(2, '0')}:${String(minutes % 60).padStart(2, '0')}`;
      return { start: time(startMinutes), end: time(startMinutes + 30), break_text: index === bellRows.length - 1 ? '' : '5 мин' };
    });
    renderBellRows();
    toast('Стандартные значения подставлены. Нажмите «Сохранить звонки».');
  });
  $('#bellsSave').addEventListener('click', async () => {
    if (!bellRows.length) return toast('Добавьте хотя бы одну пару.');
    if (bellRows.some(row => !row.start || !row.end || row.end <= row.start)) return toast('Проверьте время: конец пары должен быть позже начала.');
    const button = $('#bellsSave'); button.disabled = true;
    try {
      const data = await api('admin/bells', { method: 'PUT', body: { day_type: bellsDay, is_short: bellsShort, is_active: true, rows: bellRows } });
      toast(`${data.message} Профиль применён на киоске.`);
      await loadBells();
    } catch (error) { toast(error.message); } finally { button.disabled = false; }
  });

  // УЧЕБНАЯ ПРАКТИКА
  let practiceCache = [];
  let practiceGroups = [];
  let practiceLessons = [];
  let editingPracticeId = null;

  function practiceIso(date) {
    const pad = value => String(value).padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
  }

  function practiceRange(start, end) {
    if (!start || !end || start > end) return [];
    const dates = [];
    const current = new Date(`${start}T12:00:00`);
    const last = new Date(`${end}T12:00:00`);
    while (current <= last && dates.length < 367) {
      if (current.getDay() !== 0) dates.push(practiceIso(current));
      current.setDate(current.getDate() + 1);
    }
    return dates;
  }

  function practiceGridDates() {
    return [...new Set(practiceLessons.map(lesson => lesson.date))].sort();
  }

  function renderPracticeGrid() {
    const dates = practiceGridDates();
    $('#practiceGridHead').innerHTML = `<tr><th scope="col">Пара</th>${dates.map(date => {
      const label = new Intl.DateTimeFormat('ru-RU', { day: '2-digit', month: '2-digit', weekday: 'short' }).format(new Date(`${date}T12:00:00`));
      const [weekday, day] = label.split(', ');
      return `<th scope="col"><span class="practice-grid__date">${escapeHtml(day || label)}</span><span class="practice-grid__weekday">${escapeHtml(weekday || '')}</span></th>`;
    }).join('')}</tr>`;
    $('#practiceGridBody').innerHTML = Array.from({ length: 7 }, (_, index) => {
      const pair = index + 1;
      return `<tr><td class="num">${pair}</td>${dates.map(date => {
        const lesson = practiceLessons.find(item => item.date === date && item.pair === pair);
        return `<td><input class="cell-input" data-date="${date}" data-pair="${pair}" value="${escapeAttr(lesson ? lesson.room : '')}" maxlength="30" aria-label="Аудитория, ${date}, пара ${pair}"></td>`;
      }).join('')}</tr>`;
    }).join('');
  }

  function rebuildPracticeGrid() {
    const start = $('#practiceDateStart').value;
    const end = $('#practiceDateEnd').value;
    const dates = practiceRange(start, end);
    if (!dates.length) return toast('Проверьте период: выберите даты с понедельника по субботу.');
    const previous = new Map(practiceLessons.map(lesson => [`${lesson.date}:${lesson.pair}`, lesson.room]));
    practiceLessons = dates.flatMap(date => Array.from({ length: 7 }, (_, index) => ({
      date, pair: index + 1, room: previous.get(`${date}:${index + 1}`) || ''
    })));
    renderPracticeGrid();
  }

  async function loadPractice() {
    const [practiceData, groupsData] = await Promise.all([api('admin/practice'), api('admin/groups')]);
    practiceCache = practiceData.blocks;
    practiceGroups = groupsData.groups;
    $('#practiceGroup').innerHTML = practiceGroups.map(group => `<option value="${group.id}">${escapeHtml(group.code)} · ${group.course} курс</option>`).join('');
    const body = $('#practiceBody');
    if (!practiceCache.length) {
      body.innerHTML = '<tr><td colspan="6"><div class="empty"><p class="empty__title">Блоков практики пока нет</p><p>Добавьте первый блок кнопкой выше.</p></div></td></tr>';
      return;
    }
    body.innerHTML = practiceCache.map(block => `<tr>
      <td><div class="cell-main">${escapeHtml(block.group)}</div><div class="cell-sub">${block.course} курс</div></td>
      <td><div class="cell-main">${escapeHtml(block.module)}</div><div class="cell-sub">${escapeHtml(block.specialty)}</div>${block.is_active ? '' : '<span class="badge badge--muted" style="margin-top:6px">Скрыт</span>'}</td>
      <td style="white-space:nowrap">${formatDate(block.date_start)}<div class="cell-sub">— ${formatDate(block.date_end)}</div></td>
      <td>${escapeHtml(block.subgroup || '—')}</td><td>${escapeHtml(block.teacher || '—')}</td>
      <td class="cell-actions"><button class="icon-btn" data-practice-edit="${block.id}" aria-label="Редактировать блок"><svg class="icon"><use href="#i-edit"/></svg></button><button class="icon-btn icon-btn--danger" data-practice-delete="${block.id}" aria-label="Удалить блок"><svg class="icon"><use href="#i-trash"/></svg></button></td>
    </tr>`).join('');
  }

  function openPractice(block = null) {
    editingPracticeId = block ? block.id : null;
    $('#modalPracticeTitle').textContent = block ? `Практика · группа ${block.group}` : 'Добавить блок практики';
    $('#practiceGroup').value = block ? block.group_id : (practiceGroups[0]?.id || '');
    $('#practiceModule').value = block ? block.module : '';
    $('#practiceSpecialty').value = block ? block.specialty : '';
    $('#practiceSubgroup').value = block ? block.subgroup : '';
    $('#practiceTeacher').value = block ? block.teacher : '';
    const today = new Date();
    const nextWeek = new Date(today); nextWeek.setDate(today.getDate() + 6);
    $('#practiceDateStart').value = block ? block.date_start : practiceIso(today);
    $('#practiceDateEnd').value = block ? block.date_end : practiceIso(nextWeek);
    $('#practiceActive').checked = block ? block.is_active : true;
    practiceLessons = block ? block.lessons.map(lesson => ({ date: lesson.date, pair: lesson.pair, room: lesson.room })) : [];
    setError($('#practiceModule'), ''); setError($('#practiceSpecialty'), '');
    if (practiceLessons.length) renderPracticeGrid(); else rebuildPracticeGrid();
    openModal('modalPractice');
  }

  $('#practiceAdd').addEventListener('click', () => openPractice());
  $('#practiceBody').addEventListener('click', event => {
    const edit = event.target.closest('[data-practice-edit]');
    const remove = event.target.closest('[data-practice-delete]');
    if (edit) openPractice(practiceCache.find(block => block.id === Number(edit.dataset.practiceEdit)));
    if (remove) {
      const block = practiceCache.find(item => item.id === Number(remove.dataset.practiceDelete));
      askConfirm(`Удалить блок практики группы ${block.group} с ${formatDate(block.date_start)} по ${formatDate(block.date_end)}?`, async () => {
        try { const data = await api('admin/practice/item', { method: 'DELETE', query: `&id=${block.id}` }); toast(data.message); await loadPractice(); }
        catch (error) { toast(error.message); }
      });
    }
  });
  $('#practiceDateStart').addEventListener('change', rebuildPracticeGrid);
  $('#practiceDateEnd').addEventListener('change', rebuildPracticeGrid);
  $('#practiceGridBody').addEventListener('input', event => {
    const input = event.target.closest('input[data-date]');
    if (!input) return;
    const lesson = practiceLessons.find(item => item.date === input.dataset.date && item.pair === Number(input.dataset.pair));
    if (lesson) lesson.room = input.value;
  });
  $('#practiceForm').addEventListener('submit', async event => {
    event.preventDefault();
    const validModule = setError($('#practiceModule'), $('#practiceModule').value.trim() ? '' : 'Укажите модуль');
    const validSpecialty = setError($('#practiceSpecialty'), $('#practiceSpecialty').value.trim() ? '' : 'Укажите специальность');
    if (!validModule || !validSpecialty) return;
    if (!$('#practiceGroup').value) return toast('Выберите группу.');
    if (!$('#practiceDateStart').value || !$('#practiceDateEnd').value || !practiceLessons.length) return toast('Укажите период и сформируйте сетку уроков.');
    const current = practiceCache.find(block => block.id === editingPracticeId);
    const body = {
      group_id: Number($('#practiceGroup').value), module: $('#practiceModule').value.trim(),
      specialty: $('#practiceSpecialty').value.trim(), subgroup: $('#practiceSubgroup').value.trim(),
      teacher: $('#practiceTeacher').value.trim(), date_start: $('#practiceDateStart').value,
      date_end: $('#practiceDateEnd').value, is_active: $('#practiceActive').checked,
      sort_order: current ? current.sort_order : null, lessons: practiceLessons
    };
    const submit = $('#practiceSubmit'); submit.disabled = true;
    try {
      const data = await api(editingPracticeId ? 'admin/practice/item' : 'admin/practice', {
        method: editingPracticeId ? 'PUT' : 'POST', query: editingPracticeId ? `&id=${editingPracticeId}` : '', body
      });
      closeModal($('#modalPractice')); toast(data.message); await loadPractice();
    } catch (error) { toast(error.message, 6500); } finally { submit.disabled = false; }
  });

  // СОТРУДНИКИ
  let staffCache = [];
  let teacherCategory = 'teachers';
  let editingStaffId = null;
  let staffPhotoPath = '';

  function photoPreview(element, path) {
    element.innerHTML = path ? `<img src="${escapeAttr(asset(path))}" alt="Выбранное изображение">` : '<svg class="icon"><use href="#i-image"/></svg>';
  }

  async function uploadImage(file, preview) {
    if (!file) return null;
    if (file.size > 5 * 1024 * 1024) throw new Error('Размер изображения не должен превышать 5 МБ.');
    if (!/^image\/(jpeg|png|webp)$/.test(file.type)) throw new Error('Поддерживаются только JPG, PNG и WEBP.');
    if (preview) preview.innerHTML = `<img src="${escapeAttr(URL.createObjectURL(file))}" alt="Загружаемое изображение">`;
    const form = new FormData(); form.append('file', file);
    const data = await api('admin/upload', { method: 'POST', body: form });
    return data.path;
  }

  async function loadStaff() {
    const data = await api('admin/staff');
    staffCache = data.staff;
    renderStaff();
  }

  function renderStaff() {
    const query = $('#teacherSearch').value.trim().toLocaleLowerCase('ru');
    const items = staffCache.filter(person => person.category === teacherCategory)
      .filter(person => !query || `${person.full_name} ${person.position} ${person.qualification}`.toLocaleLowerCase('ru').includes(query));
    const grid = $('#teacherGrid');
    if (!items.length) {
      grid.innerHTML = '<div class="empty" style="grid-column:1/-1"><p class="empty__title">Сотрудники не найдены</p><p>Измените поисковый запрос или добавьте новую запись.</p></div>';
      return;
    }
    grid.innerHTML = items.map(person => `<article class="staff-card ${person.is_active ? '' : 'is-inactive'}">
      ${person.photo_path ? `<img class="staff-card__photo" src="${escapeAttr(asset(person.photo_path))}" alt="">` : `<span class="staff-card__photo staff-card__photo--empty">${escapeHtml(initials(person.full_name))}</span>`}
      <div class="staff-card__info"><div class="staff-card__name">${escapeHtml(person.full_name)}</div><div class="staff-card__post">${escapeHtml(person.position)}</div>${person.is_active ? '' : '<span class="badge badge--muted" style="margin-top:6px">Скрыт</span>'}</div>
      <div class="staff-card__actions"><button class="icon-btn" data-staff-edit="${person.id}" aria-label="Редактировать ${escapeAttr(person.full_name)}"><svg class="icon"><use href="#i-edit"/></svg></button><button class="icon-btn icon-btn--danger" data-staff-delete="${person.id}" aria-label="Удалить ${escapeAttr(person.full_name)}"><svg class="icon"><use href="#i-trash"/></svg></button></div>
    </article>`).join('');
  }

  function openStaff(person = null) {
    editingStaffId = person ? person.id : null;
    staffPhotoPath = person ? person.photo_path : '';
    $('#modalTeacherTitle').textContent = person ? 'Редактировать сотрудника' : 'Добавить сотрудника';
    $('#teacherName').value = person ? person.full_name : '';
    $('#teacherPost').value = person ? person.position : '';
    $('#teacherCat').value = person ? person.category : teacherCategory;
    $('#teacherQual').value = person ? person.qualification : '';
    $('#teacherRoom').value = person ? person.room : '';
    $('#teacherHead').value = person ? person.department_head : '';
    $('#teacherInfo').value = person ? person.description : '';
    $('#teacherActive').checked = person ? person.is_active : true;
    $('#teacherHeadFlag').checked = person ? person.is_head : false;
    $('#teacherPhoto').value = '';
    photoPreview($('#teacherPhotoPreview'), staffPhotoPath);
    setError($('#teacherName'), ''); setError($('#teacherPost'), '');
    openModal('modalTeacher');
  }

  $$('[data-tcat]').forEach(button => button.addEventListener('click', () => {
    teacherCategory = button.dataset.tcat;
    $$('[data-tcat]').forEach(item => { const active = item === button; item.classList.toggle('is-on', active); item.setAttribute('aria-selected', String(active)); });
    renderStaff();
  }));
  $('#teacherSearch').addEventListener('input', renderStaff);
  $('#teacherAdd').addEventListener('click', () => openStaff());
  $('#teacherGrid').addEventListener('click', event => {
    const edit = event.target.closest('[data-staff-edit]');
    const remove = event.target.closest('[data-staff-delete]');
    if (edit) openStaff(staffCache.find(person => person.id === Number(edit.dataset.staffEdit)));
    if (remove) {
      const person = staffCache.find(item => item.id === Number(remove.dataset.staffDelete));
      askConfirm(`Удалить сотрудника «${person.full_name}»? Запись исчезнет и на киоске.`, async () => {
        try { const data = await api('admin/staff/item', { method: 'DELETE', query: `&id=${person.id}` }); toast(data.message); await loadStaff(); }
        catch (error) { toast(error.message); }
      });
    }
  });
  $('#teacherPhotoBtn').addEventListener('click', () => $('#teacherPhoto').click());
  $('#teacherPhoto').addEventListener('change', async event => {
    const button = $('#teacherPhotoBtn'); button.disabled = true;
    try { const path = await uploadImage(event.target.files[0], $('#teacherPhotoPreview')); if (path) staffPhotoPath = path; toast('Фотография загружена.'); }
    catch (error) { toast(error.message); photoPreview($('#teacherPhotoPreview'), staffPhotoPath); }
    finally { button.disabled = false; }
  });
  $('#teacherForm').addEventListener('submit', async event => {
    event.preventDefault();
    const validName = setError($('#teacherName'), $('#teacherName').value.trim() ? '' : 'Введите ФИО');
    const validPost = setError($('#teacherPost'), $('#teacherPost').value.trim() ? '' : 'Укажите предмет или должность');
    if (!validName || !validPost) return;
    const body = {
      category: $('#teacherCat').value, full_name: $('#teacherName').value.trim(), position: $('#teacherPost').value.trim(),
      qualification: $('#teacherQual').value.trim(), room: $('#teacherRoom').value.trim(), department_head: $('#teacherHead').value.trim(),
      description: $('#teacherInfo').value.trim(), photo_path: staffPhotoPath, is_active: $('#teacherActive').checked, is_head: $('#teacherHeadFlag').checked
    };
    const submit = event.target.querySelector('button[type="submit"]'); submit.disabled = true;
    try {
      const data = await api(editingStaffId ? 'admin/staff/item' : 'admin/staff', { method: editingStaffId ? 'PUT' : 'POST', query: editingStaffId ? `&id=${editingStaffId}` : '', body });
      closeModal($('#modalTeacher')); toast(data.message); teacherCategory = body.category; await loadStaff();
    } catch (error) { toast(error.message); } finally { submit.disabled = false; }
  });


  // НОВОСТИ И АФИША
  const postsCache = { news: [], events: [] };
  let postKind = 'news';
  let editingPostId = null;
  let postImagePath = '';

  function formatDate(value, withTime = '') {
    if (!value) return '—';
    const date = new Date(`${value}T00:00:00`);
    const formatted = new Intl.DateTimeFormat('ru-RU', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(date);
    return formatted + (withTime ? ` · ${withTime}` : '');
  }

  function statusBadge(status) {
    return status === 'published' ? '<span class="badge badge--ok">Опубликовано</span>' : '<span class="badge badge--muted">Черновик</span>';
  }

  function postThumb(item) {
    return item.image_path ? `<img class="post-thumb" src="${escapeAttr(asset(item.image_path))}" alt="">` : '<span class="post-thumb post-thumb--empty"><svg class="icon"><use href="#i-image"/></svg></span>';
  }

  function renderPosts(kind) {
    const body = $(kind === 'news' ? '#newsBody' : '#eventsBody');
    const items = postsCache[kind];
    if (!items.length) {
      body.innerHTML = `<tr><td colspan="6"><div class="empty"><p class="empty__title">${kind === 'news' ? 'Новостей пока нет' : 'Событий пока нет'}</p><p>Создайте первую публикацию кнопкой выше.</p></div></td></tr>`;
      return;
    }
    body.innerHTML = items.map(item => {
      const middle = kind === 'news'
        ? `<td>${escapeHtml(item.category)}</td><td>${formatDate(item.published_at)}</td>`
        : `<td>${formatDate(item.event_date, item.event_time)}</td><td>${escapeHtml(item.place || '—')}</td>`;
      return `<tr><td>${postThumb(item)}</td><td><div class="cell-main">${escapeHtml(item.title)}</div><div class="cell-sub post-excerpt">${escapeHtml(item.summary || '')}</div></td>${middle}<td>${statusBadge(item.status)}</td><td class="cell-actions"><button class="icon-btn" data-post-edit="${item.id}" aria-label="Редактировать"><svg class="icon"><use href="#i-edit"/></svg></button><button class="icon-btn icon-btn--danger" data-post-delete="${item.id}" aria-label="Удалить"><svg class="icon"><use href="#i-trash"/></svg></button></td></tr>`;
    }).join('');
  }

  async function loadPosts(kind) {
    const data = await api(`admin/${kind}`);
    postsCache[kind] = data.items;
    renderPosts(kind);
  }

  function openPost(kind, item = null) {
    postKind = kind; editingPostId = item ? item.id : null; postImagePath = item ? item.image_path : '';
    const isNews = kind === 'news';
    $('#modalPostTitle').textContent = item ? (isNews ? 'Редактировать новость' : 'Редактировать событие') : (isNews ? 'Новая новость' : 'Новое событие');
    $('#postDateLabel').textContent = isNews ? 'Дата публикации' : 'Дата события';
    $('#postCatWrap').hidden = !isNews;
    $('#postTextWrap').hidden = !isNews;
    ['#postTimeWrap', '#postPlaceWrap', '#postRoomWrap'].forEach(selector => { $(selector).hidden = isNews; });
    $('#postTitle').value = item ? item.title : '';
    $('#postDate').value = item ? (isNews ? item.published_at : item.event_date) : new Date().toISOString().slice(0, 10);
    $('#postCat').value = item && isNews ? item.category : 'События';
    $('#postTime').value = item && !isNews ? item.event_time : '';
    $('#postPlace').value = item && !isNews ? item.place : '';
    $('#postRoom').value = item && !isNews ? item.room_key : '';
    $('#postStatus').value = item ? item.status : 'published';
    $('#postSummary').value = item ? item.summary : '';
    $('#postText').value = item && isNews ? item.description : '';
    $('#postCounter').textContent = `${$('#postText').value.length} / 10000`;
    $('#postSubmit').textContent = item ? 'Сохранить изменения' : (isNews ? 'Сохранить новость' : 'Сохранить событие');
    $('#postPhoto').value = '';
    photoPreview($('#postPhotoPreview'), postImagePath);
    setError($('#postTitle'), ''); setError($('#postSummary'), '');
    openModal('modalPost');
  }

  $('#newsAdd').addEventListener('click', () => openPost('news'));
  $('#eventAdd').addEventListener('click', () => openPost('events'));
  ['news', 'events'].forEach(kind => {
    $(kind === 'news' ? '#newsBody' : '#eventsBody').addEventListener('click', event => {
      const edit = event.target.closest('[data-post-edit]');
      const remove = event.target.closest('[data-post-delete]');
      if (edit) openPost(kind, postsCache[kind].find(item => item.id === Number(edit.dataset.postEdit)));
      if (remove) {
        const item = postsCache[kind].find(post => post.id === Number(remove.dataset.postDelete));
        askConfirm(`Удалить публикацию «${item.title}»? Она сразу исчезнет с киоска.`, async () => {
          try { const data = await api(`admin/${kind}/item`, { method: 'DELETE', query: `&id=${item.id}` }); toast(data.message); await loadPosts(kind); }
          catch (error) { toast(error.message); }
        });
      }
    });
  });
  $('#postText').addEventListener('input', () => { $('#postCounter').textContent = `${$('#postText').value.length} / 10000`; });
  $('#postPhotoBtn').addEventListener('click', () => $('#postPhoto').click());
  $('#postPhoto').addEventListener('change', async event => {
    const button = $('#postPhotoBtn'); button.disabled = true;
    try { const path = await uploadImage(event.target.files[0], $('#postPhotoPreview')); if (path) postImagePath = path; toast('Обложка загружена.'); }
    catch (error) { toast(error.message); photoPreview($('#postPhotoPreview'), postImagePath); }
    finally { button.disabled = false; }
  });
  $('#postForm').addEventListener('submit', async event => {
    event.preventDefault();
    const validTitle = setError($('#postTitle'), $('#postTitle').value.trim() ? '' : 'Введите заголовок');
    const validSummary = setError($('#postSummary'), $('#postSummary').value.trim().length >= 10 ? '' : 'Добавьте анонс не короче 10 символов');
    if (!validTitle || !validSummary) return;
    if (!$('#postDate').value) return toast('Укажите дату публикации.');
    if (postKind === 'news' && !$('#postCat').value.trim()) return toast('Укажите категорию новости.');
    const body = {
      title: $('#postTitle').value.trim(), status: $('#postStatus').value, image_path: postImagePath,
      summary: $('#postSummary').value.trim(), description: postKind === 'news' ? $('#postText').value.trim() : ($('#postSummary').value.trim())
    };
    if (postKind === 'news') {
      Object.assign(body, { category: $('#postCat').value.trim(), published_at: $('#postDate').value });
    } else {
      Object.assign(body, { event_date: $('#postDate').value, event_time: $('#postTime').value, place: $('#postPlace').value.trim(), room_key: $('#postRoom').value.trim() });
    }
    const submit = $('#postSubmit'); submit.disabled = true;
    try {
      const data = await api(editingPostId ? `admin/${postKind}/item` : `admin/${postKind}`, { method: editingPostId ? 'PUT' : 'POST', query: editingPostId ? `&id=${editingPostId}` : '', body });
      closeModal($('#modalPost')); toast(data.message); await loadPosts(postKind);
    } catch (error) { toast(error.message); } finally { submit.disabled = false; }
  });

  // КАРТА ЭТАЖЕЙ
  const MAP_NS = 'http://www.w3.org/2000/svg';
  const MAP_W = 1240; // размеры полотна схемы (как на киоске, js/map.js)
  const MAP_H = 720;
  let mapFloors = [];
  let mapFloorId = null;
  let mapSelectedId = null;
  let mapSelectedNodeId = null;
  let mapSelectedEdge = null;
  let mapMode = 'rooms';
  let mapDrag = null;
  let mapNodeDrag = null;
  let mapSuppressClickUntil = 0;

  const mapFloor = () => mapFloors.find(floor => floor.id === mapFloorId) || null;
  const mapSelected = () => {
    const floor = mapFloor();
    return floor ? floor.rooms.find(room => room.id === mapSelectedId) || null : null;
  };
  const mapSelectedNode = () => {
    const floor = mapFloor();
    return floor ? floor.route_nodes.find(node => node.id === mapSelectedNodeId) || null : null;
  };

  function svgNode(tag, attrs) {
    const node = document.createElementNS(MAP_NS, tag);
    Object.entries(attrs || {}).forEach(([key, value]) => node.setAttribute(key, value));
    return node;
  }

  function markMapState(text, kind = 'muted') {
    const el = $('#mapState');
    el.textContent = text;
    el.className = `badge badge--${kind}`;
  }

  function mapPoint(event) {
    const rect = $('#mapSvg').getBoundingClientRect();
    return {
      x: Math.round(Math.min(MAP_W, Math.max(0, (event.clientX - rect.left) * MAP_W / rect.width))),
      y: Math.round(Math.min(MAP_H, Math.max(0, (event.clientY - rect.top) * MAP_H / rect.height)))
    };
  }

  async function loadMap() {
    markMapState('Загрузка…', 'muted');
    const data = await api('admin/map');
    mapFloors = data.floors;
    if (!mapFloor() && mapFloors.length) mapFloorId = mapFloors[0].id;
    $('#mapFloor').innerHTML = mapFloors.map(floor => `<option value="${floor.id}">${escapeHtml(floor.title)}</option>`).join('');
    if (mapFloor()) $('#mapFloor').value = mapFloorId;
    if (!mapSelected()) mapSelectedId = null;
    if (!mapSelectedNode()) mapSelectedNodeId = null;
    drawMap();
  }

  function syncUnderlayControls(floor) {
    $('#mapUnderlayOpacity').value = floor.underlay_opacity;
    $('#mapUnderlayScale').value = floor.underlay_scale;
    $('#mapUnderlayOpacityValue').textContent = `${Math.round(floor.underlay_opacity * 100)}%`;
    $('#mapUnderlayScaleValue').textContent = `${Math.round(floor.underlay_scale * 100)}%`;
    $('#mapUnderlayPath').textContent = floor.underlay_path || 'Подложка не задана';
  }

  function appendUnderlay(svg, floor) {
    if (!floor.underlay_path) return;
    const scale = floor.underlay_scale;
    svg.appendChild(svgNode('image', {
      href: asset(floor.underlay_path),
      x: (MAP_W - MAP_W * scale) / 2, y: (MAP_H - MAP_H * scale) / 2,
      width: MAP_W * scale, height: MAP_H * scale,
      opacity: floor.underlay_opacity, preserveAspectRatio: 'xMidYMid meet',
      class: 'map-editor__underlay'
    }));
  }

  function appendResizeHandles(svg, room) {
    const points = {
      nw: [room.x, room.y], n: [room.x + room.w / 2, room.y], ne: [room.x + room.w, room.y],
      e: [room.x + room.w, room.y + room.h / 2], se: [room.x + room.w, room.y + room.h],
      s: [room.x + room.w / 2, room.y + room.h], sw: [room.x, room.y + room.h],
      w: [room.x, room.y + room.h / 2]
    };
    Object.entries(points).forEach(([handle, [x, y]]) => {
      const marker = svgNode('rect', {
        x: x - 8, y: y - 8, width: 16, height: 16, rx: 2,
        class: 'map-resize-handle', 'data-handle': handle
      });
      marker.addEventListener('pointerdown', event => mapResizeStart(event, room, handle));
      svg.appendChild(marker);
    });
  }

  function drawMap() {
    const floor = mapFloor();
    const svg = $('#mapSvg');
    svg.innerHTML = '';
    if (!floor) { markMapState('Этажи не найдены', 'warn'); return; }

    $('#mapModeRooms').classList.toggle('is-on', mapMode === 'rooms');
    $('#mapModeRoutes').classList.toggle('is-on', mapMode === 'routes');
    $('#mapModeRooms').setAttribute('aria-selected', String(mapMode === 'rooms'));
    $('#mapModeRoutes').setAttribute('aria-selected', String(mapMode === 'routes'));
    $('#mapRoomAdd').hidden = mapMode !== 'rooms';
    $('#mapNodeKindWrap').hidden = mapMode !== 'routes';
    $('#mapEditorHint').textContent = mapMode === 'rooms'
      ? 'Потяните помещение или маркер на его границе. Координаты и размеры сохраняются автоматически.'
      : 'Клик по пустому месту добавляет узел. Кликните по двум узлам для соединения; перетаскивайте узлы мышью. Клик по ребру открывает удаление.';
    markMapState(mapMode === 'rooms' ? `${floor.rooms.length} помещений` : `${floor.route_nodes.length} узлов · ${floor.route_edges.length} рёбер`, 'ok');
    syncUnderlayControls(floor);
    appendUnderlay(svg, floor);

    const wall = svgNode('rect', { x: 20, y: 20, width: 1200, height: 680, rx: 6, class: 'map-editor__wall' });
    if (floor.underlay_path) wall.setAttribute('fill', 'none');
    svg.appendChild(wall);
    svg.appendChild(svgNode('rect', { x: 40, y: 320, width: 1160, height: 80, class: 'map-editor__corridor' }));

    floor.rooms.forEach(room => {
      const group = svgNode('g', {
        class: `map-room map-room--${room.type}${room.id === mapSelectedId && mapMode === 'rooms' ? ' is-selected' : ''}${mapMode === 'routes' ? ' is-network-view' : ''}`,
        'data-room': room.id
      });
      group.appendChild(svgNode('rect', { x: room.x, y: room.y, width: room.w, height: room.h, rx: 4 }));
      if (room.type === 'stairs') {
        const size = Math.max(18, Math.min(room.w, room.h) * 0.52);
        group.appendChild(svgNode('use', {
          href: '#i-stairs',
          x: room.x + room.w / 2 - size / 2, y: room.y + room.h / 2 - size / 2,
          width: size, height: size, class: 'map-editor__room-icon'
        }));
      } else {
        const label = svgNode('text', { x: room.x + room.w / 2, y: room.y + room.h / 2, 'dominant-baseline': 'middle' });
        const code = room.room_key || room.name;
        label.textContent = code.length > 10 ? code.slice(0, 9) + '…' : code;
        group.appendChild(label);
      }
      if (mapMode === 'rooms') group.addEventListener('pointerdown', event => mapDragStart(event, room));
      svg.appendChild(group);
    });
    if (mapMode === 'rooms' && mapSelected()) appendResizeHandles(svg, mapSelected());

    if (mapMode === 'routes') {
      floor.route_edges.forEach(edge => {
        const a = floor.route_nodes.find(node => node.id === edge.node_a);
        const b = floor.route_nodes.find(node => node.id === edge.node_b);
        if (!a || !b) return;
        const selected = mapSelectedEdge && mapSelectedEdge.node_a === edge.node_a && mapSelectedEdge.node_b === edge.node_b;
        const group = svgNode('g', { 'data-edge': `${edge.node_a}-${edge.node_b}`, class: 'map-route-edge' });
        group.appendChild(svgNode('line', { x1: a.x, y1: a.y, x2: b.x, y2: b.y, class: 'map-route-edge__hit' }));
        group.appendChild(svgNode('line', { x1: a.x, y1: a.y, x2: b.x, y2: b.y, class: `map-route-edge__line${selected ? ' is-selected' : ''}` }));
        group.addEventListener('click', event => {
          event.stopPropagation();
          if (Date.now() < mapSuppressClickUntil) return;
          mapSelectedNodeId = null;
          mapSelectedEdge = { node_a: edge.node_a, node_b: edge.node_b };
          drawMap();
        });
        svg.appendChild(group);
      });
      floor.route_nodes.forEach(node => {
        const group = svgNode('g', {
          class: `map-route-node map-route-node--${node.kind}${node.id === mapSelectedNodeId ? ' is-selected' : ''}`,
          'data-node': node.id
        });
        group.appendChild(svgNode('circle', { cx: node.x, cy: node.y, r: 14 }));
        const label = svgNode('text', { x: node.x, y: node.y - 22 });
        label.textContent = node.room_key || `#${node.id}`;
        group.appendChild(label);
        group.addEventListener('pointerdown', event => mapNodeDragStart(event, node));
        svg.appendChild(group);
      });
    }
    renderRoomCard();
    renderNodeCard();
    renderEdgeCard();
  }

  /* Перетаскивание помещения мышью; сохранение x/y при отпускании */
  function mapDragStart(event, room) {
    if (event.button !== 0) return;
    event.preventDefault();
    const svg = $('#mapSvg');
    mapDrag = { room, startX: event.clientX, startY: event.clientY, origX: room.x, origY: room.y, moved: false };
    svg.setPointerCapture(event.pointerId);
    const group = svg.querySelector(`g[data-room="${room.id}"]`);
    group.classList.add('is-dragging');

    const onMove = moveEvent => {
      if (!mapDrag) return;
      const rect = svg.getBoundingClientRect();
      const scale = rect.width / MAP_W;
      const dx = (moveEvent.clientX - mapDrag.startX) / scale;
      const dy = (moveEvent.clientY - mapDrag.startY) / scale;
      if (!mapDrag.moved && Math.abs(dx) + Math.abs(dy) < 4) return;
      mapDrag.moved = true;
      // не даём вытащить помещение за контур этажа
      const nextX = Math.round(Math.min(Math.max(mapDrag.origX + dx, 20), 1220 - room.w));
      const nextY = Math.round(Math.min(Math.max(mapDrag.origY + dy, 20), 700 - room.h));
      mapDrag.nextX = nextX;
      mapDrag.nextY = nextY;
      group.setAttribute('transform', `translate(${nextX - mapDrag.origX},${nextY - mapDrag.origY})`);
    };
    const onUp = () => {
      svg.removeEventListener('pointermove', onMove);
      svg.removeEventListener('pointerup', onUp);
      svg.removeEventListener('pointercancel', onUp);
      group.classList.remove('is-dragging');
      if (!mapDrag) return;
      const drag = mapDrag;
      mapDrag = null;
      if (!drag.moved) { // обычный клик — выбрать помещение
        mapSelectedId = room.id;
        drawMap();
        return;
      }
      drag.room.x = drag.nextX;
      drag.room.y = drag.nextY;
      mapSelectedId = room.id;
      drawMap();
      saveRoomPos(drag.room);
    };
    svg.addEventListener('pointermove', onMove);
    svg.addEventListener('pointerup', onUp);
    svg.addEventListener('pointercancel', onUp);
  }

  /* Изменение размеров за углы и стороны выбранного помещения. */
  function mapResizeStart(event, room, handle) {
    if (event.button !== 0) return;
    event.preventDefault();
    event.stopPropagation();
    const svg = $('#mapSvg');
    const drag = { startX: event.clientX, startY: event.clientY, x: room.x, y: room.y, w: room.w, h: room.h, moved: false };
    svg.setPointerCapture(event.pointerId);
    const onMove = moveEvent => {
      const rect = svg.getBoundingClientRect();
      const dx = (moveEvent.clientX - drag.startX) * MAP_W / rect.width;
      const dy = (moveEvent.clientY - drag.startY) * MAP_H / rect.height;
      if (!drag.moved && Math.abs(dx) + Math.abs(dy) < 3) return;
      drag.moved = true;
      let left = drag.x;
      let right = drag.x + drag.w;
      let top = drag.y;
      let bottom = drag.y + drag.h;
      if (handle.includes('w')) left = Math.min(right - 20, Math.max(20, drag.x + dx));
      if (handle.includes('e')) right = Math.max(left + 20, Math.min(1220, drag.x + drag.w + dx));
      if (handle.includes('n')) top = Math.min(bottom - 20, Math.max(20, drag.y + dy));
      if (handle.includes('s')) bottom = Math.max(top + 20, Math.min(700, drag.y + drag.h + dy));
      room.x = Math.round(left); room.y = Math.round(top);
      room.w = Math.round(right - left); room.h = Math.round(bottom - top);
      drawMap();
    };
    const onUp = () => {
      svg.removeEventListener('pointermove', onMove);
      svg.removeEventListener('pointerup', onUp);
      svg.removeEventListener('pointercancel', onUp);
      if (!drag.moved) return;
      mapSuppressClickUntil = Date.now() + 250;
      saveRoomPos(room);
    };
    svg.addEventListener('pointermove', onMove);
    svg.addEventListener('pointerup', onUp);
    svg.addEventListener('pointercancel', onUp);
  }

  /* Узлы перетаскиваются так же, как помещения; клик по двум узлам создаёт ребро. */
  function mapNodeDragStart(event, node) {
    if (event.button !== 0) return;
    event.preventDefault();
    event.stopPropagation();
    const svg = $('#mapSvg');
    mapNodeDrag = { node, startX: event.clientX, startY: event.clientY, x: node.x, y: node.y, moved: false };
    svg.setPointerCapture(event.pointerId);
    const onMove = moveEvent => {
      if (!mapNodeDrag) return;
      const rect = svg.getBoundingClientRect();
      const dx = (moveEvent.clientX - mapNodeDrag.startX) * MAP_W / rect.width;
      const dy = (moveEvent.clientY - mapNodeDrag.startY) * MAP_H / rect.height;
      if (!mapNodeDrag.moved && Math.abs(dx) + Math.abs(dy) < 4) return;
      mapNodeDrag.moved = true;
      node.x = Math.round(Math.min(1220, Math.max(20, mapNodeDrag.x + dx)));
      node.y = Math.round(Math.min(700, Math.max(20, mapNodeDrag.y + dy)));
      drawMap();
    };
    const onUp = () => {
      svg.removeEventListener('pointermove', onMove);
      svg.removeEventListener('pointerup', onUp);
      svg.removeEventListener('pointercancel', onUp);
      const drag = mapNodeDrag;
      mapNodeDrag = null;
      if (!drag) return;
      if (drag.moved) {
        mapSuppressClickUntil = Date.now() + 250;
        mapSelectedNodeId = node.id;
        mapSelectedEdge = null;
        drawMap();
        saveNodePos(node);
        return;
      }
      mapSelectedEdge = null;
      if (mapSelectedNodeId && mapSelectedNodeId !== node.id) {
        connectNodes(mapSelectedNodeId, node.id);
      } else {
        mapSelectedNodeId = node.id;
        drawMap();
      }
    };
    svg.addEventListener('pointermove', onMove);
    svg.addEventListener('pointerup', onUp);
    svg.addEventListener('pointercancel', onUp);
  }

  async function saveNodePos(node) {
    markMapState('Сохранение…', 'muted');
    try {
      const data = await api('admin/map/node', {
        method: 'PUT', query: `&id=${node.id}`,
        body: { x: node.x, y: node.y, kind: node.kind, room_key: node.room_key || '' }
      });
      markMapState('Сохранено · только что', 'ok');
      toast(data.message);
    } catch (error) {
      toast(error.message);
      await loadMap();
    }
  }

  async function connectNodes(nodeA, nodeB) {
    markMapState('Сохранение…', 'muted');
    try {
      const data = await api('admin/map/edge', { method: 'POST', body: { node_a: nodeA, node_b: nodeB } });
      mapSelectedNodeId = nodeB;
      toast(data.message);
      await loadMap();
    } catch (error) { toast(error.message); markMapState('Не сохранено', 'error'); }
  }

  async function addRouteNode(event) {
    const floor = mapFloor();
    if (!floor) return;
    const point = mapPoint(event);
    try {
      const data = await api('admin/map/node', {
        method: 'POST',
        body: { floor_id: floor.id, x: point.x, y: point.y, kind: $('#mapNodeKind').value, room_key: '' }
      });
      mapSelectedNodeId = data.id;
      mapSelectedEdge = null;
      toast(data.message);
      await loadMap();
    } catch (error) { toast(error.message); }
  }

  /* После перетаскивания — тихое сохранение новых координат */
  async function saveRoomPos(room) {
    markMapState('Сохранение…', 'muted');
    try {
      await api('admin/map/item', {
        method: 'PUT', query: `&id=${room.id}`,
        body: { name: room.name, type: room.type, x: room.x, y: room.y, w: room.w, h: room.h }
      });
      markMapState('Сохранено · только что', 'ok');
      toast(`«${room.name}»: координаты и размеры сохранены.`);
    } catch (error) {
      toast(error.message);
      await loadMap(); // вернуть помещение на место из базы
    }
  }

  /* Карточки выбранного помещения, узла или ребра. */
  function renderRoomCard() {
    const room = mapSelected();
    const card = $('#mapRoomCard');
    if (!room || mapMode !== 'rooms') { card.hidden = true; return; }
    card.hidden = false;
    $('#mapRoomTitle').textContent = room.name;
    $('#mapRoomKey').textContent = `Код: ${room.room_key} · этаж «${mapFloor().short_title}»`;
    $('#mapRoomName').value = room.name;
    $('#mapRoomKeyInput').value = room.room_key;
    $('#mapRoomType').value = room.type;
    $('#mapRoomX').value = room.x;
    $('#mapRoomY').value = room.y;
    $('#mapRoomW').value = room.w;
    $('#mapRoomH').value = room.h;
    setError($('#mapRoomName'), '');
    setError($('#mapRoomKeyInput'), '');
  }

  function renderNodeCard() {
    const node = mapSelectedNode();
    const card = $('#mapNodeCard');
    if (!node || mapMode !== 'routes') { card.hidden = true; return; }
    card.hidden = false;
    $('#mapNodeTitle').textContent = `Узел #${node.id} · этаж «${mapFloor().short_title}». Выберите второй узел для соединения.`;
    $('#mapNodeType').value = node.kind;
    $('#mapNodeRoomKey').value = node.room_key || '';
    $('#mapNodeX').value = node.x;
    $('#mapNodeY').value = node.y;
  }

  function renderEdgeCard() {
    const card = $('#mapEdgeCard');
    if (!mapSelectedEdge || mapMode !== 'routes') { card.hidden = true; return; }
    card.hidden = false;
    $('#mapEdgeTitle').textContent = `Узлы #${mapSelectedEdge.node_a} и #${mapSelectedEdge.node_b}`;
  }

  function setMapMode(mode) {
    mapMode = mode;
    mapSelectedId = null;
    mapSelectedNodeId = null;
    mapSelectedEdge = null;
    drawMap();
  }

  $('#mapModeRooms').addEventListener('click', () => setMapMode('rooms'));
  $('#mapModeRoutes').addEventListener('click', () => setMapMode('routes'));
  $('#mapFloor').addEventListener('change', () => {
    mapFloorId = Number($('#mapFloor').value);
    mapSelectedId = null;
    mapSelectedNodeId = null;
    mapSelectedEdge = null;
    $('#mapUnderlayFile').value = '';
    drawMap();
  });

  $('#mapSvg').addEventListener('click', event => {
    if (Date.now() < mapSuppressClickUntil || event.target.closest('[data-room],[data-node],[data-edge],.map-resize-handle')) return;
    if (mapMode === 'routes') addRouteNode(event);
    else if (mapSelectedId) { mapSelectedId = null; drawMap(); }
  });

  $('#mapRoomClose').addEventListener('click', () => { mapSelectedId = null; drawMap(); });

  $('#mapRoomSave').addEventListener('click', async () => {
    const room = mapSelected();
    if (!room) return;
    const validName = setError($('#mapRoomName'), $('#mapRoomName').value.trim() ? '' : 'Введите название');
    const validKey = setError($('#mapRoomKeyInput'), /^[A-Za-z0-9][A-Za-z0-9_-]{0,99}$/.test($('#mapRoomKeyInput').value.trim()) ? '' : 'Латиница, цифры, дефис (например, 305)');
    if (!validName || !validKey) return;
    const coords = ['X', 'Y', 'W', 'H'].map(key => Number($(`#mapRoom${key}`).value));
    if (coords.some(value => !Number.isInteger(value))) return toast('Координаты и размеры должны быть целыми числами.');
    const button = $('#mapRoomSave'); button.disabled = true;
    try {
      const data = await api('admin/map/item', {
        method: 'PUT', query: `&id=${room.id}`,
        body: { name: $('#mapRoomName').value.trim(), room_key: $('#mapRoomKeyInput').value.trim(), type: $('#mapRoomType').value, x: coords[0], y: coords[1], w: coords[2], h: coords[3] }
      });
      toast(data.message);
      await loadMap();
    } catch (error) { toast(error.message); } finally { button.disabled = false; }
  });

  $('#mapRoomDelete').addEventListener('click', () => {
    const room = mapSelected();
    if (!room) return;
    askConfirm(`Удалить помещение «${room.name}» со схемы этажа? Оно сразу исчезнет с киоска.`, async () => {
      try {
        const data = await api('admin/map/item', { method: 'DELETE', query: `&id=${room.id}` });
        mapSelectedId = null;
        toast(data.message);
        await loadMap();
      } catch (error) { toast(error.message); }
    });
  });

  $('#mapRoomAdd').addEventListener('click', () => {
    const floor = mapFloor();
    if (!floor) return;
    $('#roomForm').reset();
    setError($('#roomKey'), ''); setError($('#roomName'), '');
    openModal('modalRoom');
  });

  $('#roomForm').addEventListener('submit', async event => {
    event.preventDefault();
    const validKey = setError($('#roomKey'), /^[A-Za-z0-9][A-Za-z0-9_-]{0,99}$/.test($('#roomKey').value.trim()) ? '' : 'Латиница, цифры, дефис (например, 305)');
    const validName = setError($('#roomName'), $('#roomName').value.trim() ? '' : 'Введите название');
    if (!validKey || !validName) return;
    const submit = event.target.querySelector('button[type="submit"]'); submit.disabled = true;
    try {
      const data = await api('admin/map', {
        method: 'POST',
        body: { floor_id: mapFloorId, room_key: $('#roomKey').value.trim(), name: $('#roomName').value.trim(), type: $('#roomType').value }
      });
      closeModal($('#modalRoom'));
      mapSelectedId = data.id;
      toast(data.message);
      await loadMap();
    } catch (error) { setError($('#roomKey'), error.message); toast(error.message); }
    finally { submit.disabled = false; }
  });

  async function saveUnderlay() {
    const floor = mapFloor();
    if (!floor) return;
    const button = $('#mapUnderlaySave');
    button.disabled = true;
    try {
      const data = await api('admin/map/floor', {
        method: 'PUT',
        body: {
          floor_id: floor.id, underlay_path: floor.underlay_path,
          underlay_opacity: Number($('#mapUnderlayOpacity').value),
          underlay_scale: Number($('#mapUnderlayScale').value)
        }
      });
      toast(data.message);
      await loadMap();
    } catch (error) { toast(error.message); } finally { button.disabled = false; }
  }

  $('#mapUnderlayUpload').addEventListener('click', () => $('#mapUnderlayFile').click());
  $('#mapUnderlayFile').addEventListener('change', async event => {
    const floor = mapFloor();
    const file = event.target.files[0];
    if (!floor || !file) return;
    const button = $('#mapUnderlayUpload');
    button.disabled = true;
    try {
      floor.underlay_path = await uploadImage(file, null);
      drawMap();
      toast('Изображение загружено. Нажмите «Сохранить подложку».');
    } catch (error) { toast(error.message); } finally { button.disabled = false; }
  });
  $('#mapUnderlayClear').addEventListener('click', () => {
    const floor = mapFloor();
    if (!floor) return;
    floor.underlay_path = '';
    $('#mapUnderlayFile').value = '';
    drawMap();
  });
  ['Opacity', 'Scale'].forEach(name => {
    $(`#mapUnderlay${name}`).addEventListener('input', event => {
      const floor = mapFloor();
      if (!floor) return;
      floor[`underlay_${name.toLowerCase()}`] = Number(event.target.value);
      drawMap();
    });
  });
  $('#mapUnderlaySave').addEventListener('click', saveUnderlay);

  $('#mapNodeSave').addEventListener('click', async () => {
    const node = mapSelectedNode();
    if (!node) return;
    const x = Number($('#mapNodeX').value);
    const y = Number($('#mapNodeY').value);
    const roomKey = $('#mapNodeRoomKey').value.trim();
    if (!Number.isInteger(x) || !Number.isInteger(y)) return toast('Координаты узла должны быть целыми числами.');
    if (roomKey && !/^[A-Za-z0-9][A-Za-z0-9_-]{0,99}$/.test(roomKey)) return toast('Код помещения: латиница, цифры, дефис и подчёркивание.');
    const button = $('#mapNodeSave');
    button.disabled = true;
    try {
      const data = await api('admin/map/node', {
        method: 'PUT', query: `&id=${node.id}`,
        body: { x, y, kind: $('#mapNodeType').value, room_key: roomKey }
      });
      toast(data.message);
      await loadMap();
    } catch (error) { toast(error.message); } finally { button.disabled = false; }
  });
  $('#mapNodeClose').addEventListener('click', () => { mapSelectedNodeId = null; drawMap(); });
  $('#mapNodeDelete').addEventListener('click', () => {
    const node = mapSelectedNode();
    if (!node) return;
    askConfirm(`Удалить узел #${node.id} и все его рёбра?`, async () => {
      try {
        const data = await api('admin/map/node', { method: 'DELETE', query: `&id=${node.id}` });
        mapSelectedNodeId = null;
        toast(data.message);
        await loadMap();
      } catch (error) { toast(error.message); }
    });
  });
  $('#mapEdgeDelete').addEventListener('click', () => {
    if (!mapSelectedEdge) return;
    const edge = mapSelectedEdge;
    askConfirm(`Удалить ребро между узлами #${edge.node_a} и #${edge.node_b}?`, async () => {
      try {
        const data = await api('admin/map/edge', { method: 'DELETE', body: edge });
        mapSelectedEdge = null;
        toast(data.message);
        await loadMap();
      } catch (error) { toast(error.message); }
    });
  });

  // ПОЛЬЗОВАТЕЛИ И РОЛИ
  let usersCache = [];

  async function loadUsers() {
    const data = await api('admin/users');
    usersCache = data.users;
    const body = $('#rolesBody');
    body.innerHTML = usersCache.map(user => {
      const sections = user.role === 'admin' ? 'Все разделы' : user.role === 'schedule' ? 'Занятия и звонки' : 'Сотрудники, новости, афиша';
      return `<tr><td><div class="user-table-cell"><span class="user-chip__avatar">${escapeHtml(initials(user.full_name))}</span><div><div class="cell-main">${escapeHtml(user.full_name)}</div><div class="cell-sub">${user.last_login_at ? `Последний вход: ${escapeHtml(user.last_login_at)}` : 'Ещё не входил'}</div></div></div></td><td><code>${escapeHtml(user.login)}</code></td><td>${escapeHtml(ROLE_NAMES[user.role])}</td><td>${sections}</td><td>${user.is_active ? '<span class="badge badge--ok">Активен</span>' : '<span class="badge badge--muted">Отключён</span>'}</td><td class="cell-actions"><button class="icon-btn icon-btn--danger" data-user-delete="${user.id}" aria-label="Удалить ${escapeAttr(user.full_name)}" ${currentUser && currentUser.id === user.id ? 'disabled title="Нельзя удалить собственную учётную запись"' : ''}><svg class="icon"><use href="#i-trash"/></svg></button></td></tr>`;
    }).join('');
  }

  $('#roleAdd').addEventListener('click', () => {
    $('#roleForm').reset();
    setError($('#roleName'), ''); setError($('#roleLogin'), '');
    openModal('modalRole');
  });
  $('#roleForm').addEventListener('submit', async event => {
    event.preventDefault();
    const validName = setError($('#roleName'), $('#roleName').value.trim() ? '' : 'Введите ФИО сотрудника');
    const validLogin = setError($('#roleLogin'), /^[A-Za-z0-9_.-]{3,50}$/.test($('#roleLogin').value.trim()) ? '' : '3–50 латинских букв, цифр, точек или дефисов');
    if (!validName || !validLogin) return;
    const submit = event.target.querySelector('button[type="submit"]'); submit.disabled = true;
    try {
      const data = await api('admin/users', { method: 'POST', body: { full_name: $('#roleName').value.trim(), login: $('#roleLogin').value.trim(), role: $('#roleRole').value } });
      closeModal($('#modalRole'));
      toast(data.generated_password ? `Пользователь создан. Одноразовый пароль: ${data.generated_password}` : data.message, 15000);
      await loadUsers();
    } catch (error) { setError($('#roleLogin'), error.message); toast(error.message); }
    finally { submit.disabled = false; }
  });
  $('#rolesBody').addEventListener('click', event => {
    const button = event.target.closest('[data-user-delete]'); if (!button) return;
    const user = usersCache.find(item => item.id === Number(button.dataset.userDelete));
    askConfirm(`Удалить учётную запись «${user.full_name}» (${user.login})? Доступ к панели будет закрыт.`, async () => {
      try { const data = await api('admin/users/item', { method: 'DELETE', query: `&id=${user.id}` }); toast(data.message); await loadUsers(); }
      catch (error) { toast(error.message); }
    });
  });

  // ЗАПУСК ПАНЕЛИ
  loaders.schedule = loadGroups;
  loaders.practice = loadPractice;
  loaders.bells = loadBells;
  loaders.teachers = loadStaff;
  loaders.news = () => loadPosts('news');
  loaders.events = () => loadPosts('events');
  loaders.map = loadMap;
  loaders.roles = loadUsers;

  $('#topbarDate').textContent = new Intl.DateTimeFormat('ru-RU', { day: 'numeric', month: 'long', year: 'numeric' }).format(new Date());

  async function initPanel() {
    const data = await api('me');
    currentUser = data.user; csrfToken = data.csrf_token;
    $('#userName').textContent = currentUser.full_name;
    $('#userRole').textContent = ROLE_NAMES[currentUser.role] || currentUser.role;
    $('#userAvatar').textContent = initials(currentUser.full_name);
    $$('.nav-item[data-role]').forEach(button => {
      button.hidden = currentUser.role !== 'admin' && button.dataset.role !== currentUser.role;
    });
    $$('.sidebar__label').forEach(label => {
      let sibling = label.nextElementSibling;
      let hasVisible = false;
      while (sibling && !sibling.classList.contains('sidebar__label')) {
        if (sibling.matches('.nav-item[data-role]') && !sibling.hidden) hasVisible = true;
        sibling = sibling.nextElementSibling;
      }
      label.hidden = !hasVisible;
    });
    const first = $('.nav-item[data-role]:not([hidden])');
    if (!first) throw new Error('Для этой учётной записи не назначены доступные разделы.');
    await showSection(first.dataset.section);
  }

  initPanel().catch(error => {
    console.error(error);
    if (error.message !== 'Требуется вход.') toast(error.message, 8000);
  });
})();
