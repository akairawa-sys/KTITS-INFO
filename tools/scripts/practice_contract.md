# Контракт данных «Учебная практика» (PRACTICE в bootstrap)

Общий для двух агентов (БД/API/админка и киоск).

## Таблицы (аддитивно, новая миграция tools/migration_practice.sql + KTITS-INFO.sql)

- `practice_blocks`: id, group_id (FK groups.id), module VARCHAR(180), specialty VARCHAR(180),
  subgroup VARCHAR(60) (например 'I подгруппа'), teacher VARCHAR(120),
  date_start DATE, date_end DATE, sort_order INT, is_active TINYINT(1).
- `practice_lessons`: id, block_id (FK practice_blocks.id, ON DELETE CASCADE),
  lesson_date DATE, pair_number TINYINT, room VARCHAR(30).

## JSON в bootstrap (новый ключ PRACTICE, старые ключи не менять)

```json
"PRACTICE": [
  {
    "id": 1,
    "group": "323",
    "course": 3,
    "module": "ПМ.02 «Осуществление интеграции программных модулей»",
    "specialty": "09.02.07 «Информационные системы и программирование»",
    "subgroup": "I подгруппа",
    "teacher": "Габитова Е. Н.",
    "date_start": "2026-11-17",
    "date_end": "2026-11-26",
    "lessons": [
      {"date": "2026-11-17", "pair": 1, "room": ""},
      {"date": "2026-11-17", "pair": 4, "room": "1312"}
    ]
  }
]
```

- lessons — ВСЕ ячейки сетки дата×пара (включая пустые room=''), пара 1..7.
- group — код группы из таблицы groups.code; course — groups.course.
- Подгруппа: '' если в PDF не указана.

## PDF-файлы

Лежат в C:\Users\252305\.kimi-code\sessions\wd_ktits-info_a55ca1aacccd\session_fb368477-9f7c-43f3-a8f4-d2334aff1599\attachments\
Имена начинаются с 'f_' и содержат «Расписание практики» или «ПМ».
Структура текста PDF: заголовок «РАСПИСАНИЕ УЧЕБНОЙ ПРАКТИКИ»,
модуль (ПМ.xx «...»), специальность (код «...»), «группа NNN, период прохождения практики: с «DD» МЕСЯЦ YYYY г. по «DD» МЕСЯЦ YYYY г. (X подгруппа)»,
далее сетка: «Вторник 17.11.» и т.п., строки «N пара HH.MM - HH.MM» и номера аудиторий,
«Руководитель практики: преподаватель ФАМИЛИЯ И.О.».
Группа в PDF может не совпадать с groups.code (есть 323, 327, 401, 402, 415, 424, 425, 431, 435, 305, 320) —
если группы нет в groups, создать её (course по первой цифре номера группы, curator='').
