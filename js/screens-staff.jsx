import {
  React, useState, useMemo, useContext,
  Icon, UIContext, DataContext, useParams,
} from './core.jsx';
import { PageHeading } from './screens-home.jsx';
import { EmptyState } from './screens-schedule.jsx';

const STAFF_TABS = [
  { key: 'teachers', label: 'Преподаватели' },
  { key: 'management', label: 'Руководство' },
  { key: 'departments', label: 'Отделения' },
  { key: 'itcube', label: 'IT-CUBE' },
];
const STAFF_PER_PAGE = 12;

const DEPARTMENT_INFO = {
  'Отделение «Базовая профессиональная подготовка»': {
    courses: '1 курс',
    phone: '8 (843) 203-55-55, доб. 241',
    text: 'На отделении базовой профессиональной подготовки учится первый курс всех специальностей техникума. Здесь студенты осваивают общеобразовательные и общепрофессиональные дисциплины, проходят адаптацию к учёбе в техникуме, а со второго курса переходят на профильные отделения.',
    specs: ['Все специальности техникума (первый курс обучения)'],
  },
  'Отделение «Информационные технологии»': {
    courses: '2–4 курс',
    phone: '8 (843) 203-55-55, доб. 332',
    text: 'Отделение готовит программистов и специалистов по информационным системам. Студенты изучают языки программирования, базы данных, веб-разработку и участвуют в чемпионатах по профессиональному мастерству.',
    specs: [
      '09.02.07 «Информационные системы и программирование» — квалификации: программист, разработчик веб и мультимедийных приложений, специалист по информационным системам',
    ],
  },
  'Отделение «Сетевые технологии»': {
    courses: '2–4 курс',
    phone: '8 (843) 203-55-55, доб. 303',
    text: 'Отделение готовит специалистов по компьютерным системам и сетям: сборка и обслуживание компьютерной техники, администрирование сетей, работа с интеллектуальными интегрированными системами.',
    specs: [
      '09.02.01 «Компьютерные системы и комплексы»',
      '09.02.06 «Сетевое и системное администрирование»',
      '09.02.08 «Интеллектуальные интегрированные системы»',
    ],
  },
  'Отделение «Информационная безопасность и связь»': {
    courses: '2–4 курс',
    phone: '8 (843) 203-55-55, доб. 230',
    text: 'Отделение готовит специалистов по защите информации и системам связи: криптография, техническая защита информации, эксплуатация инфокоммуникационных сетей и организация почтовой связи.',
    specs: [
      '10.02.05 «Обеспечение информационной безопасности автоматизированных систем»',
      '11.02.12 «Почтовая связь»',
      '11.02.15 «Инфокоммуникационные сети и системы связи»',
    ],
  },
};

function staffInitials(name) {
  return name.split(' ').slice(0, 2).map(part => part.charAt(0)).join('');
}

function staffCategoryLabel(cat) {
  if (!cat) return '';
  if (cat === 'высшая') return 'высшая категория';
  if (cat === '1') return 'первая категория';
  if (cat === 'СЗД') return 'совместитель';
  return cat;
}

function StaffCard({ name, role, badge, room, photo, wide, onMore }) {
  const { navigate } = useContext(UIContext);
  return (
    <article className={`staff-card${wide ? ' staff-card--wide' : ''}`}>
      <div className="staff-card__avatar">
        {photo
          ? <img src={photo} alt={name} loading="lazy" />
          : <span aria-hidden="true">{staffInitials(name)}</span>}
      </div>
      <div className="staff-card__content">
        <h3>{name}</h3>
        <p className="staff-card__role">{role}</p>
        {badge ? <span className="staff-card__badge">{badge}</span> : null}
        {room ? (
          <button
            className="staff-card__room"
            onClick={() => { window.__kioskPendingRoom = room; navigate('/map'); }}
          >каб. {room} · на карте</button>
        ) : null}
        {onMore ? (
          <button className="staff-card__more" onClick={onMore}>Подробнее</button>
        ) : null}
      </div>
    </article>
  );
}

function DepartmentDialog({ department }) {
  const info = DEPARTMENT_INFO[department.name] || {
    courses: '',
    phone: '',
    text: `Специальности отделения: ${department.spec}.`,
    specs: [],
  };
  return (
    <React.Fragment>
      <div className="dialog-meta">
        <span className="dialog-tag">Отделение</span>
        {info.courses ? <span>{info.courses}</span> : null}
      </div>
      <h2>{department.name}</h2>
      <p className="department-dialog__text">{info.text}</p>
      {info.specs.length ? (
        <React.Fragment>
          <h3 className="department-dialog__subtitle">Специальности</h3>
          <ul className="department-dialog__list">
            {info.specs.map(spec => <li key={spec}>{spec}</li>)}
          </ul>
        </React.Fragment>
      ) : null}
      <p className="department-dialog__contacts">
        Зав. отделением: {department.head}, каб. {department.room}
        {info.phone ? `, тел. ${info.phone}` : ''}
      </p>
    </React.Fragment>
  );
}

export function StaffScreen() {
  const data = useContext(DataContext);
  const { openDialog } = useContext(UIContext);
  const params = useParams();
  const tab = STAFF_TABS.some(item => item.key === params.tab) ? params.tab : 'teachers';
  const [query, setQuery] = useState('');
  const [page, setPage] = useState(1);

  const teachers = data.STAFF.teachers;
  const filtered = useMemo(() => {
    const q = query.trim().toLocaleLowerCase('ru');
    return teachers.filter(person => !q || person.n.toLocaleLowerCase('ru').includes(q) || person.subj.toLocaleLowerCase('ru').includes(q));
  }, [teachers, query]);
  const pages = Math.max(1, Math.ceil(filtered.length / STAFF_PER_PAGE));
  const currentPage = Math.min(page, pages);
  const visible = filtered.slice((currentPage - 1) * STAFF_PER_PAGE, currentPage * STAFF_PER_PAGE);

  const onSearch = (value) => { setQuery(value); setPage(1); };
  const onTab = () => { setPage(1); };

  return (
    <section className="screen screen--page screen--staff" aria-labelledby="staffTitle">
      <PageHeading title="Преподаватели" />
      <div className="tabs tabs--staff" role="tablist" aria-label="Категории сотрудников">
        {STAFF_TABS.map(item => (
          <a
            key={item.key}
            href={`#/teachers/${item.key}`}
            className={`tab${tab === item.key ? ' is-on' : ''}`}
            role="tab"
            aria-selected={tab === item.key}
            onClick={onTab}
          >{item.label}</a>
        ))}
      </div>
      {tab === 'teachers' && (
        <React.Fragment>
          <div className="staff-search">
            <label className="sr-only" htmlFor="staffSearch">Поиск преподавателя</label>
            <input
              type="search"
              id="staffSearch"
              className="field search-field"
              placeholder="Поиск по фамилии или предмету…"
              autoComplete="off"
              value={query}
              onChange={(e) => onSearch(e.target.value)}
            />
            <span className="staff-count" aria-live="polite">Найдено: {filtered.length}</span>
            {pages > 1 && (
              <nav className="pagination" aria-label="Страницы списка преподавателей">
                <button className="page-button" aria-label="Предыдущая страница" disabled={currentPage === 1} onClick={() => setPage(currentPage - 1)}>
                  <Icon name="arrow-left" />
                </button>
                <div className="page-slider">
                  <input
                    type="range"
                    className="page-slider__input"
                    min={1}
                    max={pages}
                    step={1}
                    value={currentPage}
                    onChange={(e) => setPage(Number(e.target.value))}
                    aria-label="Выбор страницы"
                    aria-valuetext={`Страница ${currentPage} из ${pages}`}
                  />
                  <span className="page-slider__label">Страница {currentPage} из {pages}</span>
                </div>
                <button className="page-button" aria-label="Следующая страница" disabled={currentPage === pages} onClick={() => setPage(currentPage + 1)}>
                  <Icon name="chevron" />
                </button>
              </nav>
            )}
          </div>
          {visible.length ? (
            <div className="staff-grid">
              {visible.map((person, index) => (
                <StaffCard
                  key={person.n + index}
                  name={person.n}
                  role={person.subj}
                  badge={staffCategoryLabel(person.cat)}
                  photo={person.photo}
                />
              ))}
            </div>
          ) : (
            <EmptyState title="Ничего не найдено" text="Попробуйте изменить фамилию или название предмета." />
          )}
        </React.Fragment>
      )}
      {tab === 'management' && (
        <div className="staff-grid staff-grid--single">
          {data.STAFF.management.map((person, index) => (
            <StaffCard key={person.name + index} name={person.name} role={person.role} room={person.room} photo={person.photo} wide />
          ))}
        </div>
      )}
      {tab === 'departments' && (
        <div className="staff-grid staff-grid--single">
          {data.STAFF.departments.map((department, index) => (
            <StaffCard
              key={department.name + index}
              name={department.name}
              role={`Зав. отделением: ${department.head}\n${department.spec}`}
              room={department.room}
              photo={department.photo}
              wide
              onMore={() => openDialog(<DepartmentDialog department={department} />)}
            />
          ))}
        </div>
      )}
      {tab === 'itcube' && (
        <div className="staff-grid staff-grid--single">
          <StaffCard name={data.STAFF.itcubeHead} role="Руководитель IT-CUBE" room="307" photo={data.STAFF.itcubeHeadPhoto} wide />
          {data.STAFF.itcube.map((person, index) => (
            <StaffCard key={person.name + index} name={person.name} role={person.subj} photo={person.photo} wide />
          ))}
        </div>
      )}
    </section>
  );
}
