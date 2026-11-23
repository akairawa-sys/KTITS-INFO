#!/usr/bin/env python3
"""Собирает расписания практики из PDF в SQL-миграцию КТИТС-ИНФО."""

import argparse
import re
import sys
from dataclasses import dataclass, field
from datetime import date, timedelta
from pathlib import Path

from pypdf import PdfReader


DEFAULT_ATTACHMENTS = Path(
    r"C:\Users\252305\.kimi-code\sessions\wd_ktits-info_a55ca1aacccd"
    r"\session_fb368477-9f7c-43f3-a8f4-d2334aff1599\attachments"
)
MONTHS = {
    "января": 1, "февраля": 2, "марта": 3, "апреля": 4,
    "мая": 5, "июня": 6, "июля": 7, "августа": 8,
    "сентября": 9, "октября": 10, "ноября": 11, "декабря": 12,
}
WEEKDAYS = {
    "понедельник": 0, "вторник": 1, "среда": 2, "четверг": 3,
    "пятница": 4, "суббота": 5, "воскресенье": 6,
}
PAIR_RE = re.compile(
    r"^\s*([1-7])\s+пара\s+\d{2}\.\d{2}\s*[-–]\s*\d{2}\.\d{2}"
)
DATE_RE = re.compile(r"(?<![\d.])(\d{2})\.(\d{2})\.?(?!\d|\.\d)")
PERIOD_RE = re.compile(
    r"группа\s+(\d+),\s+период\s+прохождения\s+практики:\s+"
    r"с\s+«(\d{1,2})»\s+([а-яё]+)\s+(\d{4})\s+г\.\s+"
    r"по\s+«(\d{1,2})»\s+([а-яё]+)\s+(\d{4})\s+г\.",
    re.IGNORECASE,
)


@dataclass
class Column:
    x: int
    weekday: int
    printed: str
    dates: list[date] = field(default_factory=list)


@dataclass
class Block:
    group: str
    module: str
    specialty: str
    subgroup: str
    teacher: str
    date_start: date
    date_end: date
    lessons: dict[tuple[str, int], str]
    source: str


def compact(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def parse_period(text: str) -> tuple[str, date, date, str]:
    match = PERIOD_RE.search(text)
    if not match:
        raise ValueError("не найдена группа или период практики")
    group, start_day, start_month, start_year, end_day, end_month, end_year = match.groups()
    try:
        start = date(int(start_year), MONTHS[start_month.lower()], int(start_day))
        end = date(int(end_year), MONTHS[end_month.lower()], int(end_day))
    except KeyError as error:
        raise ValueError(f"неизвестный месяц: {error.args[0]}") from error
    subgroup_match = re.search(r"\(([^()]*подгруппа)\)", text[match.end():], re.IGNORECASE)
    subgroup = compact(subgroup_match.group(1)) if subgroup_match else ""
    return group, start, end, subgroup


def printed_date(day: int, month: int, start: date, end: date) -> date:
    candidates = []
    for year in range(start.year - 1, end.year + 2):
        try:
            value = date(year, month, day)
        except ValueError:
            continue
        distance = 0 if start <= value <= end else min(abs((value - start).days), abs((value - end).days))
        candidates.append((distance, abs((value - start).days), value))
    if not candidates:
        raise ValueError(f"некорректная дата в сетке: {day:02}.{month:02}")
    return min(candidates)[2]


def correct_date(raw: date, weekday: int, start: date, end: date) -> date:
    candidates = []
    value = start
    while value <= end:
        if value.weekday() == weekday:
            candidates.append(value)
        value += timedelta(days=1)
    if not candidates:
        raise ValueError(f"в периоде {start} — {end} нет нужного дня недели")
    return min(candidates, key=lambda value: abs((value - raw).days))


def page_columns(lines: list[str], start: date, end: date) -> tuple[list[Column], list[str]]:
    columns: list[Column] = []
    weekday_marks: list[tuple[int, int]] = []
    corrections: list[str] = []
    for line in lines:
        if PAIR_RE.match(line):
            break
        marks = [
            (match.start(), WEEKDAYS[match.group(0).lower()])
            for match in re.finditer("|".join(WEEKDAYS), line, re.IGNORECASE)
        ]
        if marks:
            weekday_marks = marks
        matches = list(DATE_RE.finditer(line))
        if not matches:
            continue
        line_columns = []
        for date_index, match in enumerate(matches):
            if not weekday_marks:
                raise ValueError("у даты в сетке не найден день недели")
            if len(weekday_marks) == len(matches):
                weekday = weekday_marks[date_index][1]
            else:
                _, weekday = min(weekday_marks, key=lambda item: abs(item[0] - match.start()))
            raw = printed_date(int(match.group(1)), int(match.group(2)), start, end)
            actual = correct_date(raw, weekday, start, end)
            printed = match.group(0)
            if actual != raw:
                corrections.append(f"{printed} → {actual:%d.%m.%Y}")
            line_columns.append(Column(match.start(), weekday, printed, [actual]))
        if columns and len(line_columns) != len(columns):
            raise ValueError("разное число дат в строках заголовка сетки")
        if not columns:
            columns = line_columns
        else:
            for column, item in zip(columns, line_columns):
                column.dates.extend(item.dates)
    if not columns:
        raise ValueError("не найдены даты в заголовке сетки")
    flattened = [value for column in columns for value in column.dates]
    if len(flattened) != len(set(flattened)):
        raise ValueError("повторяющиеся даты после проверки дней недели")
    return columns, corrections


def cell_text(lines: list[tuple[str, bool]], index: int, columns: list[Column], prefix_end: int) -> str:
    left_boundary = 0 if index == 0 else (columns[index - 1].x + columns[index].x) // 2
    right_boundary = None if index + 1 == len(columns) else (columns[index].x + columns[index + 1].x) // 2
    parts = []
    for line, is_pair_line in lines:
        left = max(left_boundary, prefix_end) if is_pair_line and index == 0 else left_boundary
        value = line[left:right_boundary].strip() if right_boundary is not None else line[left:].strip()
        if value:
            parts.append(value)
    value = compact(" ".join(parts))
    if value.count("(") > value.count(")"):
        value += ")"
    return value


def page_lessons(lines: list[str], columns: list[Column]) -> dict[tuple[str, int], str]:
    pair_starts = [(index, PAIR_RE.match(line)) for index, line in enumerate(lines) if PAIR_RE.match(line)]
    if [int(match.group(1)) for _, match in pair_starts] != list(range(1, 8)):
        raise ValueError("в сетке должны быть строки пар 1–7")
    result: dict[tuple[str, int], str] = {}
    for position, (line_index, match) in enumerate(pair_starts):
        pair = int(match.group(1))
        next_index = pair_starts[position + 1][0] if position + 1 < len(pair_starts) else len(lines)
        row_lines = []
        for index in range(line_index, next_index):
            if index > line_index and re.search(r"Руководител\w*\s+практики:", lines[index], re.IGNORECASE):
                break
            row_lines.append((lines[index], index == line_index))
        for column in columns:
            room = cell_text(row_lines, columns.index(column), columns, match.end())
            for lesson_date in column.dates:
                result[(lesson_date.isoformat(), pair)] = room
    # «Точка кипения» в PDF занимает объединённую ячейку на две пары.
    for column in columns:
        for lesson_date in column.dates:
            for pair in range(1, 7):
                first = (lesson_date.isoformat(), pair)
                second = (lesson_date.isoformat(), pair + 1)
                if result[first].lower() == "точка" and result[second].lower() == "кипения":
                    result[first] = result[second] = "Точка кипения"
    return result


def parse_teacher(text: str) -> str:
    match = re.search(r"Руководител\w*\s+практики:?\s*(.+)$", text, re.IGNORECASE)
    if not match:
        return ""
    value = re.split(r"\s+Согласовано:", match.group(1), maxsplit=1, flags=re.IGNORECASE)[0]
    value = re.sub(r"мастер\s+производственного\s+обучения", "", value, flags=re.IGNORECASE)
    value = re.sub(r"преподавател\w*", "", value, flags=re.IGNORECASE)
    return compact(value).strip(" ,;")


def normalize_specialty(value: str) -> str:
    value = re.sub(r"\s+»", "»", compact(value))
    if " «" not in value:
        value = value.replace(" ", " «", 1)
    return value


def normalize_module(value: str) -> str:
    return re.sub(r"\s+»", "»", compact(value))


def parse_alt_page(text: str) -> tuple[str, str, str, str, date, date, dict[tuple[str, int], str]]:
    normalized = compact(text)
    group_match = re.search(r"(?:(\d+)\s+группы|группы\s+(\d+))", normalized)
    period_match = re.search(
        r"в\s+период\s+с\s+(\d{2})\.(\d{2})\.(\d{4})\s+г\."
        r"(?:\s+по\s+(\d{2})\.(\d{2})\.(\d{4})\s+г\.)?",
        normalized,
    )
    module_match = re.search(r"по\s+(ПМ\..+?«.+?»)\s+(?:\d+\s+группы|группы)", normalized)
    specialty_match = re.search(r"специальности\s+(\d{2}\.\d{2}\.\d{2}\s+«?.+?»)", normalized)
    if not all((group_match, period_match, module_match, specialty_match)):
        raise ValueError("не найдены сведения альтернативного шаблона")
    start = date(int(period_match.group(3)), int(period_match.group(2)), int(period_match.group(1)))
    end = date(int(period_match.group(6)), int(period_match.group(5)), int(period_match.group(4))) if period_match.group(4) else start + timedelta(days=6)
    subgroup_match = re.search(r"\(([^()]*подгруппа)\)", normalized[period_match.end():], re.IGNORECASE)
    subgroup = compact(subgroup_match.group(1)) if subgroup_match else ""
    lines = text.splitlines()
    columns = []
    for line in lines:
        weekdays = list(re.finditer("|".join(WEEKDAYS), line, re.IGNORECASE))
        rooms = list(re.finditer(r"аудит\.?", line, re.IGNORECASE))
        if len(weekdays) == len(rooms) and rooms:
            for weekday, room in zip(weekdays, rooms):
                weekday_number = WEEKDAYS[weekday.group(0).lower()]
                dates = []
                value = start
                while value <= end:
                    if value.weekday() == weekday_number:
                        dates.append(value)
                    value += timedelta(days=1)
                columns.append(Column(room.start(), weekday_number, "", dates))
            break
    if not columns:
        raise ValueError("не найдены колонки аудиторий")
    pair_re = re.compile(r"^\s*([1-6])(?:\s+|$)")
    pair_lines = [(line, pair_re.match(line)) for line in lines if pair_re.match(line)]
    if [int(match.group(1)) for _, match in pair_lines] != list(range(1, 7)):
        raise ValueError("в альтернативной сетке должны быть пары 1–6")
    lessons: dict[tuple[str, int], str] = {}
    group_code = group_match.group(1) or group_match.group(2)
    for line, match in pair_lines:
        pair = int(match.group(1))
        for index, column in enumerate(columns):
            room = cell_text([(line, True)], index, columns, match.end())
            room = re.sub(r"^" + re.escape(group_code) + r"(?:\s+|$)", "", room).strip()
            for lesson_date in column.dates:
                lessons[(lesson_date.isoformat(), pair)] = room
    for column in columns:
        for lesson_date in column.dates:
            lessons[(lesson_date.isoformat(), 7)] = ""
    return (
        group_match.group(1) or group_match.group(2), normalize_module(module_match.group(1)),
        normalize_specialty(specialty_match.group(1)), subgroup, start, end, lessons,
    )


def parse_pdf(path: Path) -> Block:
    reader = PdfReader(path)
    blocks = []
    teachers = []
    lessons: dict[tuple[str, int], str] = {}
    corrections = []
    for page_number, page in enumerate(reader.pages, 1):
        text = page.extract_text(extraction_mode="layout") or ""
        normalized = compact(text)
        try:
            if "Профессиональный модуль" not in normalized:
                group, module, specialty, subgroup, start, end, current_lessons = parse_alt_page(text)
                page_corrections = []
            else:
                group, start, end, subgroup = parse_period(normalized)
                module_match = re.search(r"Профессиональный\s+модуль\s+(.+?)\s+специальность", normalized, re.IGNORECASE)
                specialty_match = re.search(r"специальность\s+(\d{2}\.\d{2}\.\d{2}\s+«?.+?»)\s+группа", normalized, re.IGNORECASE)
                if not module_match or not specialty_match:
                    raise ValueError("не найден модуль или специальность")
                module = normalize_module(module_match.group(1))
                specialty = normalize_specialty(specialty_match.group(1))
                columns, page_corrections = page_columns(text.splitlines(), start, end)
                current_lessons = page_lessons(text.splitlines(), columns)
        except ValueError as error:
            raise ValueError(f"{path.name}, страница {page_number}: {error}") from error
        for key, room in current_lessons.items():
            if key in lessons and lessons[key] != room:
                raise ValueError(f"{path.name}: конфликт ячеек {key} на разных страницах")
            lessons[key] = room
        corrections.extend(page_corrections)
        teacher = parse_teacher(normalized)
        if teacher and not any(teacher in current for current in teachers):
            teachers = [current for current in teachers if current not in teacher]
            teachers.append(teacher)
        blocks.append((group, module, specialty, subgroup, start, end))
    first = blocks[0]
    if any(item[:4] != first[:4] for item in blocks[1:]):
        raise ValueError(f"{path.name}: на страницах разные сведения о блоке")
    if corrections:
        print(f"  Исправлены даты по дням недели: {', '.join(corrections)}")
    teacher = compact(", ".join(teachers))
    if len(teacher) > 120:
        raise ValueError(f"{path.name}: руководитель длиннее 120 символов")
    return Block(
        group=first[0], module=first[1], specialty=first[2], subgroup=first[3],
        teacher=teacher, date_start=min(item[4] for item in blocks),
        date_end=max(item[5] for item in blocks), lessons=lessons, source=path.name,
    )


def quote(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def schema_sql() -> str:
    return """-- Учебная практика: блоки и полная сетка аудиторий дата × пара.
SET NAMES utf8mb4;
USE `ktits_info`;

CREATE TABLE IF NOT EXISTS `practice_blocks` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `group_id` SMALLINT UNSIGNED NOT NULL,
  `module` VARCHAR(180) NOT NULL,
  `specialty` VARCHAR(180) NOT NULL,
  `subgroup` VARCHAR(60) NOT NULL DEFAULT '',
  `teacher` VARCHAR(120) NOT NULL DEFAULT '',
  `date_start` DATE NOT NULL,
  `date_end` DATE NOT NULL,
  `sort_order` INT NOT NULL DEFAULT 0,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `ix_practice_blocks_group` (`group_id`,`date_start`,`date_end`),
  CONSTRAINT `fk_practice_blocks_group` FOREIGN KEY (`group_id`) REFERENCES `groups` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `practice_lessons` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `block_id` INT UNSIGNED NOT NULL,
  `lesson_date` DATE NOT NULL,
  `pair_number` TINYINT UNSIGNED NOT NULL,
  `room` VARCHAR(30) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_practice_lesson` (`block_id`,`lesson_date`,`pair_number`),
  CONSTRAINT `fk_practice_lessons_block` FOREIGN KEY (`block_id`) REFERENCES `practice_blocks` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
"""


def data_sql(blocks: list[Block]) -> str:
    lines = ["\nSTART TRANSACTION;"]
    groups = sorted({block.group for block in blocks}, key=int)
    for group in groups:
        lines.append(
            f"INSERT INTO `groups` (`code`,`course`,`curator`) "
            f"SELECT {quote(group)},{int(group[0])},'' FROM DUAL "
            f"WHERE NOT EXISTS (SELECT 1 FROM `groups` WHERE `code`={quote(group)});"
        )
    block_ids = ", ".join(str(index) for index in range(1, len(blocks) + 1))
    lines.append(f"DELETE FROM `practice_lessons` WHERE `block_id` IN ({block_ids});")
    lines.append(f"DELETE FROM `practice_blocks` WHERE `id` IN ({block_ids});")
    for block_id, block in enumerate(blocks, 1):
        values = (
            f"{block_id},(SELECT `id` FROM `groups` WHERE `code`={quote(block.group)}),"
            f"{quote(block.module)},{quote(block.specialty)},{quote(block.subgroup)},"
            f"{quote(block.teacher)},'{block.date_start}','{block.date_end}',{block_id},1"
        )
        lines.append(
            "INSERT INTO `practice_blocks` (`id`,`group_id`,`module`,`specialty`,`subgroup`,"
            "`teacher`,`date_start`,`date_end`,`sort_order`,`is_active`) VALUES (" + values + ");"
        )
        lesson_values = [
            f"({block_id},'{lesson_date}',{pair},{quote(room)})"
            for (lesson_date, pair), room in sorted(block.lessons.items())
        ]
        lines.append(
            "INSERT INTO `practice_lessons` (`block_id`,`lesson_date`,`pair_number`,`room`) VALUES\n  "
            + ",\n  ".join(lesson_values) + ";"
        )
    lines.append("COMMIT;\n")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--attachments", type=Path, default=DEFAULT_ATTACHMENTS)
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().with_name("migration_practice.sql"))
    args = parser.parse_args()
    paths = sorted(
        path for path in args.attachments.glob("f_*.pdf")
        if "Расписание практики" in path.name or "ПМ" in path.name
    )
    if len(paths) != 20:
        print(f"Ожидалось 20 PDF, найдено: {len(paths)}", file=sys.stderr)
        return 1
    blocks = []
    try:
        for path in paths:
            block = parse_pdf(path)
            blocks.append(block)
            filled = sum(bool(room) for room in block.lessons.values())
            print(
                f"{block.group} · {block.date_start} — {block.date_end} · "
                f"{block.subgroup or 'без подгруппы'} · {len(block.lessons)} ячеек, {filled} заполнено"
            )
        if len({(block.group, block.module, block.subgroup, block.teacher) for block in blocks}) != 20:
            raise ValueError("среди PDF есть дубликаты блоков")
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return 1
    blocks.sort(key=lambda block: (block.date_start, int(block.group), block.subgroup, block.teacher, block.source))
    args.output.write_text(schema_sql() + data_sql(blocks), encoding="utf-8")
    print(f"Готово: {len(blocks)} блоков, {sum(len(block.lessons) for block in blocks)} ячеек → {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
