import { useState, useContext, Icon, UIContext, DataContext, useParams } from './core.jsx';
import { PageHeading } from './screens-home.jsx';

function PostDialog({ metaTag, metaTime, title, children, onClose }) {
  return (
    <div className="dialog-overlay" onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}>
      <div className="content-dialog" role="dialog" aria-modal="true" aria-labelledby="dialogTitle">
        <button className="dialog-close" aria-label="Закрыть" onClick={onClose} autoFocus>
          <Icon name="close" />
        </button>
        <div className="dialog-meta">
          <span className="dialog-tag">{metaTag}</span>
          <time>{metaTime}</time>
        </div>
        <h2 id="dialogTitle">{title}</h2>
        {children}
      </div>
    </div>
  );
}

function NewsCard({ item, onOpen }) {
  return (
    <article className="news-card">
      <div className={`news-card__visual${item.image ? ' news-card__visual--photo' : ''}`}>
        {item.image
          ? <img src={item.image} alt="" loading="lazy" />
          : <><Icon name={item.tag === 'Достижения' ? 'star' : 'news'} className="news-card__placeholder-icon" /><span>МЦК-КТИТС<br />{item.tag}</span></>}
      </div>
      <div className="news-card__body">
        <div className="news-card__meta"><span className="news-card__tag">{item.tag}</span><time>{item.date}</time></div>
        <h3>{item.title}</h3>
        <p>{item.text}</p>
        <button className="news-card__open" onClick={() => onOpen(item.id)}>Читать подробнее <Icon name="chevron" /></button>
      </div>
    </article>
  );
}

export function NewsScreen() {
  const data = useContext(DataContext);
  const { navigate } = useContext(UIContext);
  const params = useParams();
  const [category, setCategory] = useState('Все');
  const categories = ['Все', ...new Set(data.NEWS.map(item => item.tag))];
  const items = data.NEWS.filter(item => category === 'Все' || item.tag === category);
  const activeId = params.id ? Number(params.id) : null;
  const active = data.NEWS.find(item => item.id === activeId) || null;
  const close = () => navigate('/news');
  return (
    <section className="screen screen--page screen--news" aria-labelledby="newsTitle">
      <PageHeading title="Новости" sub="Публикации с официального сайта МЦК-КТИТС" />
      <div className="chips" aria-label="Фильтр новостей">
        {categories.map(cat => (
          <button
            key={cat}
            className={`chip${cat === category ? ' is-on' : ''}`}
            aria-pressed={cat === category}
            onClick={() => setCategory(cat)}
          >{cat}</button>
        ))}
      </div>
      {items.length ? (
        <div className="news-grid">
          {items.map(item => <NewsCard key={item.id} item={item} onOpen={(id) => navigate(`/news/${id}`)} />)}
        </div>
      ) : (
        <div className="empty-state"><h3>Новостей в этой категории нет</h3><p>Выберите другую категорию или загляните позже.</p></div>
      )}
      {active && (
        <PostDialog metaTag={active.tag} metaTime={active.date} title={active.title} onClose={close}>
          <p className="dialog-text">{active.text}</p>
          {active.details ? <p className="dialog-text">{active.details}</p> : null}
        </PostDialog>
      )}
    </section>
  );
}

function EventCard({ event, onOpen }) {
  return (
    <article className="event-card">
      <svg className="event-date event-date--svg" viewBox="0 0 112 116" role="img" aria-label={`${event.d} ${event.m}`}>
        <rect x="18" y="12" width="76" height="68" rx="10" fill="var(--color-surface)" stroke="var(--color-accent)" strokeWidth="3" />
        <path d="M18 22a10 10 0 0 1 10-10h56a10 10 0 0 1 10 10v10H18Z" fill="var(--color-accent)" />
        <path d="M38 4v12M74 4v12" stroke="var(--color-accent)" strokeWidth="5" strokeLinecap="round" />
        <text x="56" y="66" textAnchor="middle" fontSize="34" fontWeight="800" fill="var(--color-text)">{event.d}</text>
        <text x="56" y="102" textAnchor="middle" fontSize="19" fontWeight="700" fill="var(--color-text-soft)">{event.m}</text>
      </svg>
      <div>
        <h3>{event.title}</h3>
        <div className="event-card__details">
          <span><Icon name="pin" />{event.place}</span>
          <span><Icon name="clock" />{event.time}</span>
        </div>
      </div>
      <button className="btn btn--ghost" onClick={() => onOpen(event.id)}>Подробнее</button>
    </article>
  );
}

export function EventsScreen() {
  const data = useContext(DataContext);
  const { navigate, toast } = useContext(UIContext);
  const params = useParams();
  const activeId = params.id ? Number(params.id) : null;
  const active = data.EVENTS.find(event => event.id === activeId) || null;
  const close = () => navigate('/events');
  const showOnMap = (event) => {
    const room = event.room_key;
    if (!room || !(window.KioskMap && window.KioskMap.findRoom(room))) {
      toast('Место проведения пока не отмечено на карте');
      return;
    }
    window.__kioskPendingRoom = room;
    close();
    navigate('/map');
  };
  return (
    <section className="screen screen--page screen--events" aria-labelledby="eventsTitle">
      <PageHeading title="Афиша событий" sub="Официальные анонсы, даты и места проведения" />
      {data.EVENTS.length ? (
        <div className="events-list">
          {data.EVENTS.map((event, index) => (
            <EventCard key={event.id !== undefined ? event.id : index} event={event} onOpen={(id) => navigate(`/events/${id}`)} />
          ))}
        </div>
      ) : (
        <div className="events-empty">
          <Icon name="calendar" className="events-empty__icon" />
          <h3>Будущих мероприятий пока нет</h3>
          <p>Новые анонсы с датой проведения появятся здесь после следующего обновления данных администратором.</p>
        </div>
      )}
      {active && (
        <PostDialog metaTag={`${active.d} ${active.m}`} metaTime={active.time} title={active.title} onClose={close}>
          <p className="dialog-text">
            {active.description || `Мероприятие пройдёт в МЦК-КТИТС. Время начала — ${active.time}. Для участия уточните подробности у преподавателя или в учебной части.`}
          </p>
          <button className="btn btn--primary" onClick={() => showOnMap(active)}>Показать место на карте</button>
        </PostDialog>
      )}
    </section>
  );
}
