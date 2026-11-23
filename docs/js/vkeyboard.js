(function () {
  'use strict';

  const LETTERS = {
    ru: [
      ['й', 'ц', 'у', 'к', 'е', 'н', 'г', 'ш', 'щ', 'з', 'х', 'ъ'],
      ['ф', 'ы', 'в', 'а', 'п', 'р', 'о', 'л', 'д', 'ж', 'э'],
      ['я', 'ч', 'с', 'м', 'и', 'т', 'ь', 'б', 'ю', '.'],
    ],
    en: [
      ['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'],
      ['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'],
      ['z', 'x', 'c', 'v', 'b', 'n', 'm', '.'],
    ],
  };
  const DIGIT_ROWS = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['-', '/', ':', ';', '(', ')', '@', '«', '»', '?'],
    ['#', '%', '*', '+', '=', '_', '!', '"', ',', '₽'],
  ];

  const state = { mode: 'ru', shift: false };
  let board = null;
  let currentField = null;

  const isKiosk = () => {
    const kiosk = document.getElementById('kiosk');
    return Boolean(kiosk && kiosk.dataset.layout === 'portrait');
  };

  const isTextField = el => el && el.matches
    && el.matches('input[type="text"], input[type="search"], input:not([type]), textarea')
    && !el.readOnly && !el.disabled;

  const getKiosk = () => document.getElementById('kiosk');

  function build() {
    if (board) return board;
    const host = getKiosk() || document.body;
    board = document.createElement('div');
    board.className = 'vkb';
    board.setAttribute('aria-hidden', 'true');
    host.appendChild(board);
    board.addEventListener('pointerdown', event => {
      const key = event.target.closest('.vkb__key');
      if (!key) return;
      event.preventDefault();
      press(key.dataset.key, key.dataset.value);
    });
    return board;
  }

  function keyButton(key, value, label, extraClass) {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = `vkb__key${extraClass ? ' ' + extraClass : ''}`;
    btn.dataset.key = key;
    if (value !== undefined) btn.dataset.value = value;
    btn.textContent = label;
    return btn;
  }

  function render() {
    if (!board) return;
    board.innerHTML = '';
    const shifted = state.shift;
    const mode = state.mode;

    const addRow = keys => {
      const row = document.createElement('div');
      row.className = 'vkb__row';
      keys.forEach(item => row.appendChild(item));
      board.appendChild(row);
    };

    const letterRows = mode === 'digits' ? DIGIT_ROWS : LETTERS[mode].map(row => row.slice());
    letterRows.forEach((row, rowIndex) => {
      const keys = [];
      if (mode !== 'digits' && rowIndex === letterRows.length - 1) {
        keys.push(keyButton('shift', undefined, '⇧', 'vkb__key--wide' + (shifted ? ' is-on' : '')));
      }
      row.forEach(ch => {
        const shown = mode === 'digits' ? ch : (shifted ? ch.toUpperCase() : ch);
        keys.push(keyButton('char', shown, shown));
      });
      if (rowIndex === letterRows.length - 1) {
        keys.push(keyButton('backspace', undefined, '⌫', 'vkb__key--wide'));
      }
      addRow(keys);
    });

    const bottom = [];
    bottom.push(keyButton('mode', undefined, mode === 'digits' ? 'АБВ' : '123', 'vkb__key--wide'));
    if (mode !== 'digits') {
      bottom.push(keyButton('lang', undefined, mode === 'ru' ? 'RU' : 'EN', 'vkb__key--wide'));
    }
    bottom.push(keyButton('space', ' ', 'Пробел', 'vkb__key--space'));
    bottom.push(keyButton('enter', undefined, 'Ввод', 'vkb__key--wide vkb__key--action'));
    bottom.push(keyButton('hide', undefined, '▼', 'vkb__key--wide'));
    addRow(bottom);
  }

  /* Нативный setter value: React перехватывает el.value на контролируемых
     полях, поэтому присваивание через прототип — иначе onChange не срабатывает */
  function setNativeValue(el, value) {
    const proto = el instanceof HTMLTextAreaElement ? HTMLTextAreaElement.prototype : HTMLInputElement.prototype;
    Object.getOwnPropertyDescriptor(proto, 'value').set.call(el, value);
  }

  function insert(text) {
    const el = currentField;
    if (!el) return;
    const start = el.selectionStart ?? el.value.length;
    const end = el.selectionEnd ?? start;
    setNativeValue(el, el.value.slice(0, start) + text + el.value.slice(end));
    const pos = start + text.length;
    if (el.setSelectionRange) el.setSelectionRange(pos, pos);
    el.dispatchEvent(new Event('input', { bubbles: true }));
  }

  function backspace() {
    const el = currentField;
    if (!el) return;
    const start = el.selectionStart ?? el.value.length;
    const end = el.selectionEnd ?? start;
    if (start === end && start > 0) {
      setNativeValue(el, el.value.slice(0, start - 1) + el.value.slice(end));
      if (el.setSelectionRange) el.setSelectionRange(start - 1, start - 1);
    } else if (start !== end) {
      setNativeValue(el, el.value.slice(0, start) + el.value.slice(end));
      if (el.setSelectionRange) el.setSelectionRange(start, start);
    } else return;
    el.dispatchEvent(new Event('input', { bubbles: true }));
  }

  function press(key, value) {
    if (key === 'char') {
      insert(value);
      if (state.shift && /[a-zа-яё]/i.test(value)) {
        state.shift = false;
        render();
      }
      return;
    }
    if (key === 'space') { insert(' '); return; }
    if (key === 'backspace') { backspace(); return; }
    if (key === 'shift') { state.shift = !state.shift; render(); return; }
    if (key === 'lang') {
      state.mode = state.mode === 'ru' ? 'en' : 'ru';
      state.shift = false;
      render();
      return;
    }
    if (key === 'mode') {
      state.mode = state.mode === 'digits' ? 'ru' : 'digits';
      state.shift = false;
      render();
      return;
    }
    if (key === 'enter') {
      const el = currentField;
      if (el) el.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
      close();
      if (el) el.blur();
      return;
    }
    if (key === 'hide') close();
  }

  function open(field) {
    if (!isKiosk()) return;
    build();
    currentField = field;
    render();
    board.classList.add('is-open');
    board.setAttribute('aria-hidden', 'false');
  }

  function close() {
    currentField = null;
    if (board) {
      board.classList.remove('is-open');
      board.setAttribute('aria-hidden', 'true');
    }
  }

  document.addEventListener('focusin', event => {
    if (isTextField(event.target)) open(event.target);
  });

  document.addEventListener('focusout', event => {
    if (currentField && event.target === currentField) {
      const next = event.relatedTarget;
      if (next && board && board.contains(next)) return;
      close();
    }
  });

  document.addEventListener('pointerdown', event => {
    if (!currentField || !board) return;
    if (board.contains(event.target)) return;
    if (event.target === currentField || currentField.contains(event.target)) return;
    currentField.blur();
  }, true);

  window.addEventListener('resize', () => { if (currentField && !isKiosk()) close(); });
})();
