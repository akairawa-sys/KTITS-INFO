import { useContext, Icon, UIContext, DataContext, toMin } from './core.jsx';

export function PageHeading({ title, sub }) {
  const { navigate } = useContext(UIContext);
  return (
    <div className="page-heading">
      <div>
        <h2>{title}</h2>
        {sub ? <p>{sub}</p> : null}
      </div>
      <button className="btn btn--dark back-button" onClick={() => navigate('/')}>
        <Icon name="arrow-left" />На главную
      </button>
    </div>
  );
}

function Tile({ icon, title, sub, accent, wide, onClick }) {
  return (
    <button
      className={`tile${accent ? ' tile--accent' : ''}${wide ? ' tile--wide' : ''}`}
      onClick={onClick}
    >
      <span className="tile__text">
        <span className="tile__title">{title}</span>
        <span className="tile__sub">{sub}</span>
      </span>
      <Icon name={icon} className="tile__icon" />
    </button>
  );
}

export function HomeScreen() {
  const { navigate } = useContext(UIContext);
  return (
    <section className="screen screen--home is-active" aria-labelledby="homeTitle">
      <div className="home-intro">
        <h1 id="homeTitle">Добро пожаловать<br />в МЦК-КТИТС</h1>
        <p>ГАПОУ «Международный центр компетенций —<br />Казанский техникум информационных технологий и связи»</p>
      </div>
      <nav className="home-tiles" aria-label="Разделы информационного киоска">
        <Tile icon="map" title="Карта техникума" sub="поиск аудитории и маршрут" accent wide onClick={() => navigate('/map')} />
        <Tile icon="calendar" title="Расписание занятий" sub="1–4 курс · группы · аудитории" onClick={() => navigate('/schedule/group')} />
        <Tile icon="alarm" title="Расписание звонков" sub="время пар и перемен" onClick={() => navigate('/bells')} />
        <Tile icon="teacher" title="Преподаватели" sub="состав · руководство · отделения" onClick={() => navigate('/teachers/teachers')} />
        <Tile icon="news" title="Новости" sub="жизнь техникума" onClick={() => navigate('/news')} />
        <Tile icon="star" title="Афиша событий" sub="мероприятия и даты" onClick={() => navigate('/events')} />
        <Tile icon="share" title="Социальные сети" sub="QR-коды каналов техникума" onClick={() => navigate('/social')} />
      </nav>
      <a className="admin-link" href="admin/index.html">Вход для администратора</a>
    </section>
  );
}

const SOCIAL_LINKS = [
  { key: 'site', title: 'Официальный сайт', url: 'mck-ktits.ru', href: 'https://mck-ktits.ru', note: 'Новости, приёмная кампания, сведения об образовательной организации', qr: 'assets/qr/site.png' },
  { key: 'max', title: 'MAX', url: 'max.ru/id1660014523_gos', href: 'https://max.ru/id1660014523_gos', note: 'Официальный канал техникума в мессенджере MAX', qr: 'assets/qr/max.png' },
  { key: 'vk', title: 'ВКонтакте', url: 'vk.com/mck_ktits', href: 'https://vk.com/mck_ktits', note: 'Группа техникума: анонсы, фотоотчёты, жизнь колледжа', qr: 'assets/qr/vk.png' },
  { key: 'inst', title: 'Instagram', url: 'instagram.com/ktits.ru', href: 'https://www.instagram.com/ktits.ru', note: 'Фотографии мероприятий и будней МЦК-КТИТС', qr: 'assets/qr/inst.png' },
];

function SocialCard({ link }) {
  return (
    <article className={`social-card social-card--${link.key}`}>
      <div className="social-card__qr">
        <img src={link.qr} alt={`QR-код: ${link.title}`} loading="lazy" />
        <img className="social-card__qr-logo" src="assets/logo.png" alt="" aria-hidden="true" />
      </div>
      <div className="social-card__body">
        <h3>{link.title}</h3>
        <p className="social-card__url"><a href={link.href}>{link.url}</a></p>
        <p className="social-card__note">{link.note}</p>
      </div>
    </article>
  );
}

export function SocialScreen() {
  return (
    <section className="screen screen--page screen--social" aria-labelledby="socialTitle">
      <PageHeading title="Социальные сети" sub="Наведите камеру телефона на QR-код, чтобы открыть канал техникума" />
      <div className="social-grid">
        {SOCIAL_LINKS.map(link => <SocialCard key={link.key} link={link} />)}
      </div>
      <p className="social-hint">
        <Icon name="share" className="icon" />
        Все каналы ведут официальные страницы МЦК-КТИТС. Актуальные ссылки также размещены на стендах техникума.
      </p>
    </section>
  );
}

function BellTable({ id, caption, data, saturday, now }) {
  const today = now.getDay();
  const minutes = now.getHours() * 60 + now.getMinutes();
  const applicable = saturday ? today === 6 : today >= 1 && today <= 5;
  return (
    <table className="bells-table" id={id}>
      <caption className="sr-only">{caption}</caption>
      <thead>
        <tr><th scope="col">Пара</th><th scope="col">Начало</th><th scope="col">Окончание</th><th scope="col">Перемена</th></tr>
      </thead>
      <tbody>
        {data.map(bell => {
          const current = applicable && minutes >= toMin(bell.start) && minutes < toMin(bell.end);
          return (
            <tr key={bell.n} className={current ? 'is-now' : undefined}>
              <th scope="row">{bell.n} пара</th>
              <td>{bell.start}</td>
              <td>{bell.end}</td>
              <td>{bell.br ? bell.br.replace('мин', 'минут') : '—'}</td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}

export function BellsScreen({ now }) {
  const data = useContext(DataContext);
  return (
    <section className="screen screen--page screen--bells is-active" aria-labelledby="bellsTitle">
      <PageHeading title="Расписание звонков" />
      <section className="bells-section" aria-labelledby="bellsWeekTitle">
        <h3 id="bellsWeekTitle">Понедельник – пятница</h3>
        <div className="table-wrap">
          <BellTable id="bellsWeek" caption="Расписание звонков в будние дни" data={data.BELLS_WEEK} saturday={false} now={now} />
        </div>
      </section>
      <section className="bells-section" aria-labelledby="bellsSatTitle">
        <h3 id="bellsSatTitle">Суббота</h3>
        <div className="table-wrap">
          <BellTable id="bellsSat" caption="Расписание звонков в субботу" data={data.BELLS_SAT} saturday={true} now={now} />
        </div>
      </section>
    </section>
  );
}
