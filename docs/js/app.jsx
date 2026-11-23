import ReactDOM from 'react-dom/client';
import {
  useState, useEffect, useRef, useCallback, useMemo,
  Icon, parseRoute, RouteContext, UIContext, DataContext,
  fetchBootstrap, currentBell,
} from './core.jsx';
import { HomeScreen, BellsScreen, SocialScreen } from './screens-home.jsx';
import { MapScreen } from './screens-map.jsx';
import { NewsScreen, EventsScreen } from './screens-content.jsx';
import { ScheduleScreen } from './screens-schedule.jsx';
import { StaffScreen } from './screens-staff.jsx';

function KioskHeader({ now, data }) {
  const days = ['воскресенье', 'понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота'];
  const months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
  const time = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
  return (
    <header className="kiosk-header">
      <div className="brand" aria-label="КТИТС-ИНФО">
        <img src="assets/logo.png" alt="Логотип МЦК-КТИТС" className="brand__logo" />
        <span className="brand__name">КТИТС-ИНФО</span>
      </div>
      <div className="header-status">
        <time className="clock-time" dateTime={now.toISOString()}>{time}</time>
        <div className="header-status__line">
          <span className="clock-date">{days[now.getDay()]}, {now.getDate()} {months[now.getMonth()]}</span>
          <span className="now-chip">{currentBell(now, data.BELLS_WEEK, data.BELLS_SAT)}</span>
        </div>
      </div>
    </header>
  );
}

function LoadingScreen({ error, onRetry }) {
  return (
    <div className="stage">
      <div className="kiosk boot-screen" data-layout="portrait" style={{ transform: 'none' }}>
        {error ? (
          <div className="boot-error">
            <h2>Не удалось загрузить данные</h2>
            <p>Проверьте, что OpenServer запущен, MySQL доступен и файл KTITS-INFO.sql импортирован.</p>
            <button className="btn btn--primary btn--big" onClick={onRetry}>Повторить</button>
          </div>
        ) : (
          <div className="boot-loader">
            <img src="assets/logo.png" alt="" className="boot-loader__logo" />
            <p>Загружаем данные киоска…</p>
          </div>
        )}
      </div>
    </div>
  );
}

function App() {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [route, setRoute] = useState(() => parseRoute(window.location.hash));
  const [now, setNow] = useState(() => new Date());
  const [toast, setToast] = useState(null);
  const [dialog, setDialog] = useState(null);
  const [idle, setIdle] = useState({ visible: false, count: 10 });

  const kioskRef = useRef(null);
  const toastTimer = useRef(null);
  const idleTimer = useRef(null);
  const countdownTimer = useRef(null);

  const load = useCallback(() => {
    setError(null);
    fetchBootstrap().then(setData).catch(err => setError(err.message));
  }, []);
  useEffect(() => { load(); }, [load]);
  useEffect(() => {
    if (data && window.KioskMap) window.KioskMap.floorPlans = data.FLOOR_PLANS || [];
  }, [data]);

  useEffect(() => {
    const t = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(t);
  }, []);

  const navigate = useCallback((path) => {
    const hash = `#${path}`;
    if (window.location.hash === hash) {
      setRoute(parseRoute(hash));
    } else {
      window.location.hash = hash;
    }
  }, []);
  useEffect(() => {
    const onHash = () => setRoute(parseRoute(window.location.hash));
    window.addEventListener('hashchange', onHash);
    return () => window.removeEventListener('hashchange', onHash);
  }, []);

  useEffect(() => {
    document.title = `${{ home: 'Главная', map: 'Карта техникума', schedule: 'Расписание занятий', bells: 'Расписание звонков', teachers: 'Преподаватели', news: 'Новости', events: 'Афиша событий', social: 'Социальные сети' }[route.name] || 'КТИТС-ИНФО'} — КТИТС-ИНФО`;
  }, [route.name]);

  useEffect(() => {
    const fit = () => {
      const kiosk = kioskRef.current;
      const stage = kiosk && kiosk.parentElement;
      if (!kiosk || !stage) return;
      const phone = window.matchMedia('(orientation: portrait) and (max-width: 600px)').matches;
      const landscape = window.matchMedia('(orientation: landscape)').matches;
      const tablet = window.matchMedia('(orientation: landscape) and (max-width: 1599px)').matches;
      const compactLandscape = window.matchMedia('(orientation: landscape) and (max-width: 1099px)').matches;
      let sceneWidth = 1080;
      let sceneHeight = 1920;
      let layout = 'portrait';
      if (phone) { sceneWidth = 480; sceneHeight = 853; layout = 'phone'; }
      else if (tablet && compactLandscape) { sceneWidth = 960; sceneHeight = 540; layout = 'tablet'; }
      else if (tablet) { sceneWidth = 1280; sceneHeight = 800; layout = 'tablet'; }
      else if (landscape) { sceneWidth = 1920; sceneHeight = 1080; layout = 'desktop'; }
      kiosk.dataset.layout = layout;
      const style = getComputedStyle(stage);
      const availableWidth = stage.clientWidth - parseFloat(style.paddingLeft) - parseFloat(style.paddingRight);
      const availableHeight = stage.clientHeight - parseFloat(style.paddingTop) - parseFloat(style.paddingBottom);
      const scale = Math.min(availableWidth / sceneWidth, availableHeight / sceneHeight);
      kiosk.style.transform = `scale(${scale})`;
    };
    fit();
    window.addEventListener('resize', fit);
    return () => window.removeEventListener('resize', fit);
  }, [data]);

  const showToast = useCallback((message) => {
    setToast(message);
    clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToast(null), 3500);
  }, []);

  const hideIdle = useCallback(() => {
    setIdle({ visible: false, count: 10 });
    clearInterval(countdownTimer.current);
  }, []);
  const startCountdown = useCallback(() => {
    if (parseRoute(window.location.hash).name === 'home') return;
    let count = 10;
    setIdle({ visible: true, count });
    countdownTimer.current = setInterval(() => {
      count -= 1;
      if (count <= 0) {
        hideIdle();
        navigate('/');
      } else {
        setIdle({ visible: true, count });
      }
    }, 1000);
  }, [hideIdle, navigate]);
  const resetIdle = useCallback(() => {
    clearTimeout(idleTimer.current);
    hideIdle();
    idleTimer.current = setTimeout(startCountdown, 90000);
  }, [hideIdle, startCountdown]);
  useEffect(() => {
    ['pointerdown', 'keydown', 'wheel', 'touchstart'].forEach(type => {
      document.addEventListener(type, resetIdle, { passive: true });
    });
    resetIdle();
    return () => {
      ['pointerdown', 'keydown', 'wheel', 'touchstart'].forEach(type => document.removeEventListener(type, resetIdle));
      clearTimeout(idleTimer.current);
      clearInterval(countdownTimer.current);
    };
  }, [resetIdle]);

  const openDialog = useCallback((content) => setDialog({ content }), []);
  const closeDialog = useCallback(() => setDialog(null), []);

  useEffect(() => {
    if (!dialog) return;
    const onKey = (event) => { if (event.key === 'Escape') closeDialog(); };
    document.addEventListener('keydown', onKey);
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', onKey);
      document.body.style.overflow = '';
    };
  }, [dialog, closeDialog]);

  const ui = useMemo(() => ({ toast: showToast, openDialog, closeDialog, navigate }), [showToast, openDialog, closeDialog, navigate]);

  const routeValue = useMemo(() => route, [route]);

  if (!data && !error) return <LoadingScreen />;
  if (error && !data) return <LoadingScreen error={error} onRetry={load} />;

  const fullScreens = route.name === 'map' || route.name === 'teachers';

  return (
    <DataContext.Provider value={data}>
      <UIContext.Provider value={ui}>
        <RouteContext.Provider value={routeValue}>
          <div className="stage">
            <div className="kiosk" id="kiosk" ref={kioskRef}>
              {!fullScreens && <KioskHeader now={now} data={data} />}
              <main className={fullScreens ? 'screens screens--full' : 'screens'}>
                {route.name === 'home' && <HomeScreen />}
                {route.name === 'map' && <MapScreen />}
                {route.name === 'schedule' && <ScheduleScreen />}
                {route.name === 'bells' && <BellsScreen now={now} />}
                {route.name === 'teachers' && <StaffScreen />}
                {route.name === 'news' && <NewsScreen />}
                {route.name === 'events' && <EventsScreen />}
                {route.name === 'social' && <SocialScreen />}
              </main>

              {dialog && (
                <div className="dialog-overlay" onClick={(e) => { if (e.target === e.currentTarget) closeDialog(); }}>
                  <div className="content-dialog" role="dialog" aria-modal="true">
                    <button className="dialog-close" aria-label="Закрыть" onClick={closeDialog} autoFocus>
                      <Icon name="close" />
                    </button>
                    {dialog.content}
                  </div>
                </div>
              )}

              {idle.visible && (
                <div className="idle" role="dialog" aria-modal="true">
                  <button className="idle__box" onClick={resetIdle}>
                    <span className="idle__num">{idle.count}</span>
                    <span>Возврат на главный экран</span>
                    <span className="idle__sub">Коснитесь экрана, чтобы продолжить</span>
                  </button>
                </div>
              )}
              {toast && <div className="toast" role="status">{toast}</div>}
            </div>
          </div>
        </RouteContext.Provider>
      </UIContext.Provider>
    </DataContext.Provider>
  );
}

ReactDOM.createRoot(document.getElementById('app')).render(<App />);
