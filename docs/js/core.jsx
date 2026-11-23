import React, { useContext } from 'react';

export { React };
export { useState, useEffect, useRef, useCallback, useContext, useMemo } from 'react';

export const toMin = time => {
  const parts = String(time || '0:0').split(':');
  return Number(parts[0]) * 60 + Number(parts[1]);
};
export const DAYS_SHORT = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
export const Icon = ({ name, className = 'icon' }) => (
  <svg className={className} aria-hidden="true"><use href={`#i-${name}`} /></svg>
);

export function parseRoute(hash) {
  const path = (hash || '#/').replace(/^#/, '') || '/';
  const [head, param] = path.split('/').filter(Boolean);
  switch (head || '') {
    case '': return { name: 'home', params: {} };
    case 'map': return { name: 'map', params: {} };
    case 'schedule': return { name: 'schedule', params: { mode: param || 'group' } };
    case 'bells': return { name: 'bells', params: {} };
    case 'teachers': return { name: 'teachers', params: { tab: param || 'teachers' } };
    case 'news': return { name: 'news', params: param ? { id: param } : {} };
    case 'events': return { name: 'events', params: param ? { id: param } : {} };
    case 'social': return { name: 'social', params: {} };
    default: return { name: 'home', params: {} };
  }
}

export const RouteContext = React.createContext({ name: 'home', params: {} });
export const useParams = () => useContext(RouteContext).params;

export const UIContext = React.createContext({ toast: () => {}, openDialog: () => {}, closeDialog: () => {}, navigate: () => {} });
export const DataContext = React.createContext(null);

export async function fetchBootstrap() {
  const response = await fetch('api/index.php?action=bootstrap', { headers: { Accept: 'application/json' } });
  const data = await response.json();
  if (!response.ok || !data.ok) throw new Error(data.error || 'Ошибка загрузки данных');
  return data;
}

export function currentBell(now, bellsWeek, bellsSat) {
  const day = now.getDay();
  if (day === 0) return 'Выходной';
  const table = day === 6 ? bellsSat : bellsWeek;
  const minutes = now.getHours() * 60 + now.getMinutes();
  for (const bell of table) {
    if (minutes >= toMin(bell.start) && minutes < toMin(bell.end)) return `${bell.n} пара`;
    if (minutes < toMin(bell.start)) return `до ${bell.start}`;
  }
  return 'Занятия окончены';
}
