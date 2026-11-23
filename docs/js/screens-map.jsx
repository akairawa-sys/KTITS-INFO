import { useContext, useEffect, useRef, Icon, DataContext, UIContext } from './core.jsx';

export function MapScreen() {
  const data = useContext(DataContext);
  const { navigate, toast } = useContext(UIContext);
  const rootRef = useRef(null);

  useEffect(() => {
    window.KioskMap.init({
      root: rootRef.current,
      floorPlans: data.FLOOR_PLANS,
      onNavigate: () => navigate('/map'),
      onToast: toast
    });
    if (window.__kioskPendingRoom) {
      const pending = window.__kioskPendingRoom;
      window.__kioskPendingRoom = null;
      window.KioskMap.goToRoom(pending);
    }
  }, [data, navigate, toast]);

  return (
    <section className="screen screen--map is-active" aria-labelledby="mapTitle" ref={rootRef}>
      <div className="map-controls">
        <div className="page-heading">
          <div>
            <h2 id="mapTitle">Карта техникума</h2>
            <p id="mapPlanTitle">Учебный корпус — 3 этаж</p>
          </div>
          <button className="btn btn--dark back-button" onClick={() => navigate('/')}>
            <Icon name="arrow-left" />На главную
          </button>
        </div>
        <div className="autocomplete map-search-wrap">
          <label className="sr-only" htmlFor="mapSearch">Поиск помещения</label>
          <input className="field search-field" type="search" id="mapSearch"
            placeholder="Номер или название: 305, столовая…" autoComplete="off" aria-autocomplete="list"
            aria-controls="mapSearchDrop" />
          <div className="autocomplete__drop" id="mapSearchDrop" role="listbox" hidden></div>
        </div>
        <div className="corpus-switch" id="corpusSwitch" aria-label="Выбор корпуса"></div>
        <div className="floor-switch" id="floorSwitch" aria-label="Выбор этажа"></div>
        <div className="room-card" id="roomCard" aria-live="polite">
          <p className="room-card__empty">Найдите аудиторию через поиск<br />или коснитесь помещения на схеме</p>
        </div>
      </div>
      <div className="map-area">
        <svg id="mapSvg" viewBox="0 0 1240 720" preserveAspectRatio="xMidYMid meet" role="group"
          aria-label="Интерактивная схема этажа">
          <g id="mapViewport"></g>
        </svg>
        <div className="map-zoom" aria-label="Управление масштабом карты">
          <div className="map-zoom__row">
            <button id="zoomReset" aria-label="Сбросить масштаб"><Icon name="reset" /></button>
            <button id="zoomIn" aria-label="Приблизить"><Icon name="plus" /></button>
          </div>
          <button id="zoomOut" aria-label="Отдалить"><Icon name="minus" /></button>
        </div>
        <p className="map-hint" id="mapHint">Коснитесь помещения или потяните схему</p>
      </div>
    </section>
  );
}
