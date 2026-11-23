import {
  React, useState, useEffect, useRef, useMemo, useContext,
  Icon, UIContext, DataContext, useParams, toMin, DAYS_SHORT,
} from './core.jsx';
import { PageHeading } from './screens-home.jsx';

const scheduleLines = value => String(value == null ? '' : value).split('\n').map(item => item.trim()).filter(Boolean);

function scheduleSubRows(lesson) {
  const subjects = scheduleLines(lesson.subj);
  const teachers = scheduleLines(lesson.teacher);
  const rooms = scheduleLines(lesson.room);
  const count = Math.max(subjects.length, teachers.length, rooms.length, 1);
  return Array.from({ length: count }, (_, index) => ({
    subj: subjects[index] || subjects[0] || '',
    teacher: teachers[index] || teachers[0] || '',
    room: rooms[index] || rooms[0] || '',
  }));
}

function bellForDay(pair, day, bellsWeek, bellsSat) {
  return (day === 5 ? bellsSat : bellsWeek).find(bell => bell.n === pair);
}

function isNowPair(pair, day, bellsWeek, bellsSat) {
  const now = new Date();
  if (now.getDay() - 1 !== day) return false;
  const bell = bellForDay(pair, day, bellsWeek, bellsSat);
  if (!bell) return false;
  const minutes = now.getHours() * 60 + now.getMinutes();
  return minutes >= toMin(bell.start) && minutes < toMin(bell.end);
}

function RoomLink({ room }) {
  const { navigate } = useContext(UIContext);
  if (!room) return null;
  const known = window.KioskMap && window.KioskMap.findRoom && window.KioskMap.findRoom(room);
  if (!known) return <span className="room-link">{room}</span>;
  return (
    <button
      className="room-link"
      title="Показать на карте"
      onClick={() => { window.__kioskPendingRoom = room; navigate('/map'); }}
    >{room}</button>
  );
}

function DaySwitch({ day, todayIndex, onChange }) {
  return (
    <div className="day-switch" aria-label="День недели">
      {DAYS_SHORT.map((label, index) => (
        <button
          key={label}
          className={`day-button${index === day ? ' is-on' : ''}`}
          aria-pressed={index === day}
          onClick={() => onChange(index)}
        >{label}</button>
      ))}
      <button
        className={`day-button day-button--today${day === todayIndex ? ' is-on' : ''}`}
        onClick={() => onChange(todayIndex)}
      >Сегодня</button>
    </div>
  );
}

function ViewSwitch({ view, onChange }) {
  return (
    <div className="view-switch" aria-label="Период расписания">
      <button className={`day-button${view === 'day' ? ' is-on' : ''}`} aria-pressed={view === 'day'} onClick={() => onChange('day')}>День</button>
      <button className={`day-button${view === 'week' ? ' is-on' : ''}`} aria-pressed={view === 'week'} onClick={() => onChange('week')}>Неделя</button>
    </div>
  );
}

export function EmptyState({ title, text }) {
  return <div className="empty-state"><h3>{title}</h3><p>{text}</p></div>;
}

function LessonCard({ pair, day, rows, meta }) {
  const data = useContext(DataContext);
  const bell = bellForDay(pair, day, data.BELLS_WEEK, data.BELLS_SAT);
  return (
    <article className={`lesson-card${isNowPair(pair, day, data.BELLS_WEEK, data.BELLS_SAT) ? ' is-now' : ''}`}>
      <span className="lesson-card__number" aria-label={`Пара ${pair}`}>{pair}</span>
      <div className="lesson-card__body">
        <div className="lesson-card__time">{bell ? `${bell.start} – ${bell.end}` : ''}</div>
        {rows.map((row, index) => (
          <div className="lesson-row" key={index}>
            <div className="lesson-row__main">
              <div className="lesson-row__subject">{row.subj}</div>
              <div className="lesson-row__meta">{meta(row)}</div>
            </div>
            <RoomLink room={row.room} />
          </div>
        ))}
      </div>
    </article>
  );
}

function ScheduleAutocomplete({ items, placeholder, value, onPick }) {
  const [query, setQuery] = useState(value || '');
  const [open, setOpen] = useState(false);
  const wrapRef = useRef(null);
  useEffect(() => { setQuery(value || ''); }, [value]);
  useEffect(() => {
    const onDocClick = (event) => {
      if (wrapRef.current && !wrapRef.current.contains(event.target) && !event.target.closest('.vkb')) setOpen(false);
    };
    document.addEventListener('click', onDocClick);
    return () => document.removeEventListener('click', onDocClick);
  }, []);
  const found = useMemo(() => {
    const q = query.trim().toLocaleLowerCase('ru');
    if (!q) return [];
    return items.filter(item => item.toLocaleLowerCase('ru').includes(q)).slice(0, 10);
  }, [items, query]);
  const showDrop = open && query.trim() !== '';
  return (
    <div className="autocomplete" id="schedSearchWrap" ref={wrapRef}>
      <label className="sr-only" htmlFor="schedSearch">{placeholder}</label>
      <input
        className="field search-field"
        id="schedSearch"
        type="search"
        placeholder={placeholder}
        value={query}
        autoComplete="off"
        aria-autocomplete="list"
        aria-expanded={showDrop}
        onChange={(e) => { setQuery(e.target.value); setOpen(true); }}
        onFocus={() => setOpen(true)}
        onKeyDown={(e) => {
          if (e.key === 'Escape') setOpen(false);
          if (e.key === 'Enter' && found.length) {
            e.preventDefault();
            setOpen(false);
            onPick(found[0]);
          }
        }}
      />
      {showDrop && (
        <div className="autocomplete__drop" role="listbox">
          {found.length
            ? found.map(item => (
              <button
                key={item}
                className="autocomplete__item"
                role="option"
                aria-selected={item === value}
                onPointerDown={(event) => { event.preventDefault(); setOpen(false); onPick(item); }}
                onClick={() => { setOpen(false); onPick(item); }}
              >{item}</button>
            ))
            : <p className="autocomplete__empty">Ничего не найдено. Попробуйте изменить запрос.</p>}
        </div>
      )}
    </div>
  );
}

function WeekGrid({ lessons, group, onOpenDay }) {
  const cells = {};
  lessons.forEach(lesson => {
    const key = `${lesson.day}|${lesson.pair}`;
    const rows = scheduleSubRows(lesson);
    if (!cells[key]) cells[key] = { subject: rows[0].subj, room: rows[0].room, count: 0 };
    cells[key].count += rows.length;
  });
  const maxPair = Math.max(...lessons.map(lesson => lesson.pair));
  const days = [];
  for (let pair = 1; pair <= maxPair; pair += 1) {
    for (let day = 0; day < 6; day += 1) days.push([pair, day]);
  }
  return (
    <div className="week-grid">
      <span />
      {DAYS_SHORT.map((day, index) => (
        <button key={day} className="week-head" title="Открыть день" onClick={() => onOpenDay(index)}>{day}</button>
      ))}
      {Array.from({ length: maxPair }, (_, i) => i + 1).map(pair => (
        <React.Fragment key={pair}>
          <div className="week-pair">{pair}</div>
          {DAYS_SHORT.map((_, day) => {
            const cell = cells[`${day}|${pair}`];
            if (!cell) return <div key={day} className="week-cell week-cell--empty" />;
            const subject = cell.subject.length > 32 ? `${cell.subject.slice(0, 31)}…` : cell.subject;
            return (
              <div key={day} className="week-cell">
                <div className="week-cell__subject">{subject}{cell.count > 1 ? ` +${cell.count - 1}` : ''}</div>
                <div className="week-cell__room">{cell.room}</div>
              </div>
            );
          })}
        </React.Fragment>
      ))}
    </div>
  );
}

const PRACTICE_DAYS = ['Воскресенье', 'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота'];

function practiceDate(value) {
  const [year, month, day] = String(value || '').split('-').map(Number);
  if (!year || !month || !day) return null;
  return new Date(year, month - 1, day);
}

function formatPracticeDate(value, withYear = false) {
  const date = practiceDate(value);
  if (!date) return String(value || '');
  const result = `${String(date.getDate()).padStart(2, '0')}.${String(date.getMonth() + 1).padStart(2, '0')}`;
  return withYear ? `${result}.${date.getFullYear()}` : result;
}

function PracticeBlock({ block, bellsWeek, bellsSat }) {
  const lessons = Array.isArray(block.lessons) ? block.lessons : [];
  const dates = [...new Set(lessons.map(lesson => lesson.date).filter(Boolean))].sort();
  const cells = new Map(lessons.map(lesson => [`${lesson.date}|${Number(lesson.pair)}`, lesson.room || '']));
  const hasSaturday = dates.some(date => {
    const parsed = practiceDate(date);
    return parsed && parsed.getDay() === 6;
  });

  return (
    <article className="practice-block">
      <header className="practice-block__header">
        <div className="practice-block__title">
          <h3>{block.module || 'Учебная практика'}</h3>
          {block.specialty && <p>{block.specialty}</p>}
        </div>
        {block.subgroup && <span className="practice-block__subgroup">{block.subgroup}</span>}
        <dl className="practice-block__meta">
          {block.teacher && <div><dt>Руководитель</dt><dd>{block.teacher}</dd></div>}
          <div><dt>Период</dt><dd>{formatPracticeDate(block.date_start, true)} — {formatPracticeDate(block.date_end, true)}</dd></div>
        </dl>
      </header>
      {dates.length ? (
        <div
          className="practice-grid-scroll"
          tabIndex={0}
          role="region"
          aria-label={`Сетка практики группы ${block.group}${block.subgroup ? `, ${block.subgroup}` : ''}`}
        >
          <table className="practice-table" style={{ minWidth: `${180 + dates.length * 132}px` }}>
            <thead>
              <tr>
                <th className="practice-table__pair-heading" scope="col">Пара</th>
                {dates.map(date => {
                  const parsed = practiceDate(date);
                  return (
                    <th key={date} scope="col">
                      <span>{parsed ? PRACTICE_DAYS[parsed.getDay()] : ''}</span>
                      <time dateTime={date}>{formatPracticeDate(date)}</time>
                    </th>
                  );
                })}
              </tr>
            </thead>
            <tbody>
              {Array.from({ length: 7 }, (_, index) => index + 1).map(pair => {
                const bell = bellsWeek.find(item => Number(item.n) === pair);
                const saturdayBell = hasSaturday ? bellsSat.find(item => Number(item.n) === pair) : null;
                const sameTime = bell && saturdayBell && bell.start === saturdayBell.start && bell.end === saturdayBell.end;
                return (
                  <tr key={pair}>
                    <th scope="row">
                      <span>{pair} пара</span>
                      <span className="practice-table__times">
                        <time>{bell ? `${bell.start} – ${bell.end}` : ''}</time>
                        {saturdayBell && !sameTime && <time>Сб: {saturdayBell.start} – {saturdayBell.end}</time>}
                      </span>
                    </th>
                    {dates.map(date => <td key={date}>{cells.get(`${date}|${pair}`) || ''}</td>)}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      ) : <EmptyState title="Сетка практики не заполнена" text="В этом блоке пока нет дат и аудиторий." />}
    </article>
  );
}

function PracticeMode({ practice, bellsWeek, bellsSat, group, setGroup, groupsInfo }) {
  const curators = useMemo(() => {
    const map = {};
    (groupsInfo || []).forEach(item => { map[String(item.code)] = item.curator || ''; });
    return map;
  }, [groupsInfo]);
  const groups = useMemo(
    () => [...new Set(practice.map(block => String(block.group || '')).filter(Boolean))].sort((a, b) => a.localeCompare(b, 'ru', { numeric: true })),
    [practice]
  );
  const blocks = group ? practice.filter(block => String(block.group || '') === group) : [];

  if (!practice.length) {
    return <EmptyState title="Расписание практики не опубликовано" text="Данные об учебной практике пока отсутствуют." />;
  }

  return (
    <React.Fragment>
      <div className="group-picker practice-picker">
        <label htmlFor="practiceSelect">Группа</label>
        <select
          className="field group-select"
          id="practiceSelect"
          value={group || ''}
          onChange={(event) => setGroup(event.target.value || null)}
        >
          <option value="">Выберите группу</option>
          {groups.map(item => (
            <option key={item} value={item}>{item}{curators[item] ? ` — ${curators[item]}` : ''}</option>
          ))}
        </select>
      </div>
      {!group && <p className="schedule-prompt">Выберите группу, чтобы увидеть расписание практики.</p>}
      {group && (blocks.length
        ? <div className="practice-list">{blocks.map((block, index) => (
            <PracticeBlock
              key={block.id || `${block.group}-${block.subgroup}-${index}`}
              block={block}
              bellsWeek={bellsWeek}
              bellsSat={bellsSat}
            />
          ))}</div>
        : <EmptyState title="Практики для этой группы нет" text={`Для группы ${group} расписание учебной практики не опубликовано.`} />)}
    </React.Fragment>
  );
}

export function ScheduleScreen() {
  const data = useContext(DataContext);
  const params = useParams();
  const mode = ['group', 'teacher', 'room', 'practice'].includes(params.mode) ? params.mode : 'group';
  const todayIndex = Math.min(Math.max(new Date().getDay() - 1, 0), 5);
  const [course, setCourse] = useState(1);
  const [group, setGroup] = useState(null);
  const [teacher, setTeacher] = useState(null);
  const [room, setRoom] = useState(null);
  const [practiceGroup, setPracticeGroup] = useState(null);
  const [day, setDay] = useState(todayIndex);
  const [view, setView] = useState('day');
  const schedule = data.SCHEDULE_FULL;
  const practice = Array.isArray(data.PRACTICE) ? data.PRACTICE : [];

  const uniqueTeachers = useMemo(
    () => [...new Set(schedule.lessons.flatMap(lesson => scheduleLines(lesson.teacher)))].sort((a, b) => a.localeCompare(b, 'ru')),
    [schedule.lessons]
  );
  const uniqueRooms = useMemo(
    () => [...new Set(schedule.lessons.flatMap(lesson => scheduleLines(lesson.room)))].sort((a, b) => a.localeCompare(b, 'ru')),
    [schedule.lessons]
  );

  const tabs = [
    { key: 'group', label: 'По группе' },
    { key: 'teacher', label: 'По преподавателю' },
    { key: 'room', label: 'По аудитории' },
    { key: 'practice', label: 'Учебная практика' },
  ];

  return (
    <section className="screen screen--page screen--schedule" aria-labelledby="scheduleTitle">
      <PageHeading title="Расписание занятий" sub="1 семестр 2026–2027 учебного года · с 01.09.2026" />
      <div className="tabs tabs--schedule" role="tablist" aria-label="Тип расписания">
        {tabs.map(tab => (
          <a
            key={tab.key}
            href={`#/schedule/${tab.key}`}
            className={`tab${mode === tab.key ? ' is-on' : ''}`}
            role="tab"
            aria-selected={mode === tab.key}
          >{tab.label}</a>
        ))}
      </div>
      <div className="schedule-body">
        {mode === 'group' && (
          <GroupMode
            schedule={schedule} course={course} setCourse={setCourse}
            group={group} setGroup={setGroup}
            day={day} setDay={setDay} view={view} setView={setView} todayIndex={todayIndex}
          />
        )}
        {mode === 'teacher' && (
          <TeacherMode
            schedule={schedule} teachers={uniqueTeachers}
            teacher={teacher} setTeacher={setTeacher}
            day={day} setDay={setDay} todayIndex={todayIndex}
          />
        )}
        {mode === 'room' && (
          <RoomMode
            schedule={schedule} rooms={uniqueRooms}
            room={room} setRoom={setRoom}
            day={day} setDay={setDay} todayIndex={todayIndex}
          />
        )}
        {mode === 'practice' && (
          <PracticeMode
            practice={practice}
            bellsWeek={data.BELLS_WEEK}
            bellsSat={data.BELLS_SAT}
            group={practiceGroup}
            setGroup={setPracticeGroup}
            groupsInfo={schedule.groups}
          />
        )}
      </div>
    </section>
  );
}

function GroupMode({ schedule, course, setCourse, group, setGroup, day, setDay, view, setView, todayIndex }) {
  const groups = schedule.groups.filter(item => item.course === course);
  const pairs = useMemo(() => {
    if (!group) return [];
    const byPair = new Map();
    schedule.lessons
      .filter(lesson => lesson.g === group && lesson.day === day)
      .forEach(lesson => {
        if (!byPair.has(lesson.pair)) byPair.set(lesson.pair, []);
        byPair.get(lesson.pair).push(...scheduleSubRows(lesson));
      });
    return Array.from(byPair.entries()).sort((a, b) => a[0] - b[0]);
  }, [schedule.lessons, group, day]);
  const weekLessons = useMemo(
    () => (group ? schedule.lessons.filter(lesson => lesson.g === group) : []),
    [schedule.lessons, group]
  );
  return (
    <React.Fragment>
      <div className="chips course-switch" aria-label="Курс">
        {[1, 2, 3, 4].map(item => (
          <button
            key={item}
            className={`chip${item === course ? ' is-on' : ''}`}
            aria-pressed={item === course}
            onClick={() => { setCourse(item); setGroup(null); }}
          >{item} курс</button>
        ))}
      </div>
      <div className="group-picker">
        <label htmlFor="groupSelect">Группа</label>
        <select
          className="field group-select"
          id="groupSelect"
          value={group || ''}
          onChange={(e) => setGroup(e.target.value || null)}
        >
          <option value="">Выберите группу</option>
          {groups.map(item => (
            <option key={item.code} value={item.code}>{item.code}{item.curator ? ` — ${item.curator}` : ''}</option>
          ))}
        </select>
      </div>
      <div className="schedule-toolbar">
        <DaySwitch day={day} todayIndex={todayIndex} onChange={setDay} />
        <ViewSwitch view={view} onChange={setView} />
      </div>
      {!group && <p className="schedule-prompt">Выберите группу, чтобы увидеть расписание.</p>}
      <div id="schedList">
        {group && view === 'day' && (pairs.length
          ? <div className="schedule-grid">{pairs.map(([pair, rows]) => <LessonCard key={pair} pair={pair} day={day} rows={rows} meta={row => row.teacher} />)}</div>
          : <EmptyState title="Занятий нет" text={`В этот день у группы ${group} занятия не запланированы.`} />)}
        {group && view === 'week' && (weekLessons.length
          ? <WeekGrid lessons={weekLessons} group={group} onOpenDay={(d) => { setDay(d); setView('day'); }} />
          : <EmptyState title="Занятий нет" text={`Для группы ${group} занятия не запланированы.`} />)}
      </div>
    </React.Fragment>
  );
}

function TeacherMode({ schedule, teachers, teacher, setTeacher, day, setDay, todayIndex }) {
  const lessons = useMemo(() => {
    if (!teacher) return [];
    return schedule.lessons
      .filter(lesson => lesson.day === day && scheduleLines(lesson.teacher).includes(teacher))
      .sort((a, b) => a.pair - b.pair);
  }, [schedule.lessons, teacher, day]);
  return (
    <React.Fragment>
      <ScheduleAutocomplete
        items={teachers}
        placeholder="Начните вводить фамилию преподавателя…"
        value={teacher}
        onPick={setTeacher}
      />
      <div className="schedule-toolbar"><DaySwitch day={day} todayIndex={todayIndex} onChange={setDay} /></div>
      {!teacher && <p className="schedule-prompt">Найдите преподавателя, чтобы увидеть расписание.</p>}
      <div id="schedList">
        {teacher && (lessons.length
          ? <div className="schedule-grid">{lessons.map(lesson => {
              const ownRows = scheduleSubRows(lesson).filter(row => row.teacher === teacher);
              const rows = ownRows.length ? ownRows : scheduleSubRows(lesson);
              return <LessonCard key={lesson.id} pair={lesson.pair} day={day} rows={rows} meta={() => `группа ${lesson.g}`} />;
            })}</div>
          : <EmptyState title="Занятий нет" text={`В этот день у ${teacher} занятия не запланированы.`} />)}
      </div>
    </React.Fragment>
  );
}

function RoomMode({ schedule, rooms, room, setRoom, day, setDay, todayIndex }) {
  const lessons = useMemo(() => {
    if (!room) return [];
    return schedule.lessons
      .filter(lesson => lesson.day === day && scheduleLines(lesson.room).includes(room))
      .sort((a, b) => a.pair - b.pair);
  }, [schedule.lessons, room, day]);
  return (
    <React.Fragment>
      <ScheduleAutocomplete
        items={rooms}
        placeholder="Номер аудитории: 305, с/з…"
        value={room}
        onPick={setRoom}
      />
      <div className="schedule-toolbar"><DaySwitch day={day} todayIndex={todayIndex} onChange={setDay} /></div>
      {!room && <p className="schedule-prompt">Найдите аудиторию, чтобы увидеть расписание.</p>}
      <div id="schedList">
        {room && (lessons.length
          ? <div className="schedule-grid">{lessons.map(lesson => {
              const ownRows = scheduleSubRows(lesson).filter(row => row.room === room);
              const rows = ownRows.length ? ownRows : scheduleSubRows(lesson);
              return <LessonCard key={lesson.id} pair={lesson.pair} day={day} rows={rows} meta={row => `${row.teacher} · группа ${lesson.g}`} />;
            })}</div>
          : <EmptyState title="Занятий нет" text={`В этот день в аудитории ${room} занятия не запланированы.`} />)}
      </div>
    </React.Fragment>
  );
}
