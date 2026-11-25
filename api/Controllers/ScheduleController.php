<?php
declare(strict_types=1);

namespace Ktits\Controllers;

use Ktits\Core\ApiException;
use Ktits\Core\Auth;
use Ktits\Core\Config;
use Ktits\Core\Database;
use Ktits\Core\Http;
use Ktits\Core\Validator;
use Ktits\Services\SpreadsheetReader;
use PDO;

final class ScheduleController
{
    private function pdo(): PDO
    {
        return Database::pdo();
    }

    public function groups(): void
    {
        Auth::require('schedule');
        $groups = $this->pdo()->query('SELECT id, code, course, curator FROM `groups` ORDER BY course, code')->fetchAll();
        Http::json(['ok' => true, 'groups' => \array_map(static fn ($g) => [
            'id' => (int)$g['id'], 'code' => $g['code'], 'course' => (int)$g['course'], 'curator' => $g['curator'],
        ], $groups)]);
    }

    private function lessons(PDO $pdo, int $groupId, int $day, bool $forUpdate = false): array
    {
        $sql = 'SELECT id, pair_number, subject, teacher, room, is_cancelled, UNIX_TIMESTAMP(updated_at) AS updated_at FROM lessons WHERE group_id = ? AND day_of_week = ? ORDER BY pair_number, id';
        $stmt = $pdo->prepare($sql . ($forUpdate ? ' FOR UPDATE' : ''));
        $stmt->execute([$groupId, $day]);
        return $stmt->fetchAll();
    }

    private function version(array $rows): string
    {
        return \md5(\serialize($rows));
    }

    public function get(): void
    {
        Auth::require('schedule');
        $groupId = Validator::id($_GET['group_id'] ?? 0);
        $day = Validator::id($_GET['day'] ?? 0);
        if ($day > 6) {
            Http::error('День недели должен быть от 1 до 6.');
        }
        $rows = $this->lessons($this->pdo(), $groupId, $day);
        Http::json(['ok' => true, 'version' => $this->version($rows), 'rows' => \array_map(static fn ($row) => [
            'id' => (int)$row['id'], 'pair_number' => (int)$row['pair_number'],
            'subject' => $row['subject'], 'teacher' => $row['teacher'], 'room' => $row['room'],
            'is_cancelled' => (bool)$row['is_cancelled'],
        ], $rows)]);
    }

    public function save(): void
    {
        Auth::require('schedule');
        Auth::requireCsrf();
        $input = Http::input();
        $groupId = Validator::id($input['group_id'] ?? 0);
        $day = Validator::id($input['day'] ?? 0);
        if ($day > 6) {
            Http::error('День недели должен быть от 1 до 6.');
        }
        $rows = $input['rows'] ?? null;
        if (!\is_array($rows) || \count($rows) > 8) {
            Http::error('Передайте не более 8 занятий.');
        }
        $expectedVersion = $input['version'] ?? null;
        if ($expectedVersion !== null && !\is_string($expectedVersion)) {
            throw new ApiException('Некорректная версия расписания.');
        }
        $prepared = [];
        foreach (\array_values($rows) as $index => $row) {
            if (!\is_array($row)) {
                Http::error('Некорректная строка расписания.');
            }
            $pairNumber = isset($row['pair_number']) ? Validator::id($row['pair_number']) : $index + 1;
            if ($pairNumber > 8) {
                Http::error('Номер пары должен быть от 1 до 8.');
            }
            $prepared[] = [
                'pair' => $pairNumber,
                'subject' => Validator::requireString($row, 'subject', 500),
                'teacher' => Validator::clean($row['teacher'] ?? '', 500),
                'room' => Validator::clean($row['room'] ?? '', 500),
                'cancelled' => !empty($row['is_cancelled']) ? 1 : 0,
            ];
        }
        $pdo = $this->pdo();
        $exists = $pdo->prepare('SELECT id FROM `groups` WHERE id = ?');
        $exists->execute([$groupId]);
        if (!$exists->fetch()) {
            Http::error('Группа не найдена.', 404);
        }
        $pdo->beginTransaction();
        try {
            $currentVersion = $this->version($this->lessons($pdo, $groupId, $day, true));
            if ($expectedVersion !== null && !\hash_equals($currentVersion, $expectedVersion)) {
                throw new ApiException('Расписание уже изменил другой редактор. Обновите страницу и повторите сохранение', 409);
            }
            $pdo->prepare('DELETE FROM lessons WHERE group_id = ? AND day_of_week = ?')->execute([$groupId, $day]);
            $insert = $pdo->prepare('INSERT INTO lessons (group_id, day_of_week, pair_number, subject, teacher, room, is_cancelled) VALUES (?, ?, ?, ?, ?, ?, ?)');
            foreach ($prepared as $row) {
                $insert->execute([$groupId, $day, $row['pair'], $row['subject'], $row['teacher'], $row['room'], $row['cancelled']]);
            }
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
        Auth::log('save', 'schedule', $groupId . ':' . $day, ['rows' => \count($rows)]);
        Http::json(['ok' => true, 'message' => 'Расписание сохранено и уже доступно на киоске.']);
    }

    public function import(): void
    {
        Auth::require('schedule');
        Auth::requireCsrf();
        $file = $_FILES['file'] ?? null;
        if (!$file || $file['error'] !== UPLOAD_ERR_OK) {
            Http::error('Выберите файл расписания.');
        }
        if ($file['size'] > (int)Config::get('max_import_size')) {
            Http::error('Файл расписания не должен превышать 10 МБ.');
        }
        $rows = SpreadsheetReader::read($file['tmp_name'], $file['name']);
        if (!$rows) {
            Http::error('Файл пуст.');
        }
        $header = \array_map(static function ($value) {
            $value = \function_exists('mb_strtolower') ? \mb_strtolower(\trim((string)$value), 'UTF-8') : \strtolower(\trim((string)$value));
            return \preg_replace('/\s+/u', ' ', $value);
        }, \array_shift($rows));
        $aliases = [
            'group' => ['группа', 'group'],
            'day' => ['день', 'день недели', 'day'],
            'pair' => ['№ пары', 'пара', '№', 'pair'],
            'subject' => ['предмет', 'дисциплина', 'subject'],
            'teacher' => ['преподаватель', 'teacher'],
            'room' => ['аудитория', 'кабинет', 'room'],
        ];
        $columns = [];
        foreach ($aliases as $key => $names) {
            $index = \array_search($header[0] ?? '', $names, true);
            if ($index === false) {
                foreach ($header as $i => $title) {
                    if (\in_array($title, $names, true)) {
                        $index = $i;
                        break;
                    }
                }
            }
            if ($index === false && \in_array($key, ['group', 'day', 'pair', 'subject'], true)) {
                Http::error('Не найдена обязательная колонка «' . $names[0] . '».');
            }
            $columns[$key] = $index;
        }

        $groupRows = $this->pdo()->query('SELECT id, code FROM `groups`')->fetchAll();
        $groups = [];
        foreach ($groupRows as $group) {
            $groups[$group['code']] = (int)$group['id'];
        }
        $dayNames = [
            'понедельник' => 1, 'вторник' => 2, 'среда' => 3, 'четверг' => 4, 'пятница' => 5, 'суббота' => 6,
            'пн' => 1, 'вт' => 2, 'ср' => 3, 'чт' => 4, 'пт' => 5, 'сб' => 6,
            '1' => 1, '2' => 2, '3' => 3, '4' => 4, '5' => 5, '6' => 6,
        ];
        $lessons = [];
        $errors = [];
        foreach ($rows as $offset => $row) {
            $line = $offset + 2;
            $get = static fn ($key) => $columns[$key] === false ? '' : \trim((string)($row[$columns[$key]] ?? ''));
            if ($get('group') === '' && $get('subject') === '') {
                continue;
            }
            $groupCode = $get('group');
            $dayValue = \function_exists('mb_strtolower') ? \mb_strtolower($get('day'), 'UTF-8') : \strtolower($get('day'));
            $pair = \filter_var($get('pair'), FILTER_VALIDATE_INT);
            $subject = $get('subject');
            if (!isset($groups[$groupCode])) {
                $errors[] = "Строка {$line}: неизвестная группа «{$groupCode}».";
                continue;
            }
            if (!isset($dayNames[$dayValue])) {
                $errors[] = "Строка {$line}: неизвестный день «{$get('day')}».";
                continue;
            }
            if ($pair === false || $pair < 1 || $pair > 8) {
                $errors[] = "Строка {$line}: номер пары должен быть от 1 до 8.";
                continue;
            }
            if ($subject === '') {
                $errors[] = "Строка {$line}: не указан предмет.";
                continue;
            }
            $day = $dayNames[$dayValue];
            $lessons[] = [
                'group_id' => $groups[$groupCode], 'day' => $day, 'pair' => $pair,
                'subject' => Validator::clean($subject, 500), 'teacher' => Validator::clean($get('teacher'), 500),
                'room' => Validator::clean($get('room'), 500),
            ];
            if (\count($errors) >= 20) {
                break;
            }
        }
        if ($errors) {
            Http::error('Файл содержит ошибки. Ничего не импортировано.', 422, ['details' => $errors]);
        }
        if (!$lessons) {
            Http::error('В файле не найдено занятий для импорта.');
        }

        $combos = [];
        foreach ($lessons as $lesson) {
            $combos[$lesson['group_id'] . ':' . $lesson['day']] = [$lesson['group_id'], $lesson['day']];
        }
        $pdo = $this->pdo();
        $pdo->beginTransaction();
        try {
            $delete = $pdo->prepare('DELETE FROM lessons WHERE group_id = ? AND day_of_week = ?');
            foreach ($combos as $combo) {
                $delete->execute($combo);
            }
            $insert = $pdo->prepare('INSERT INTO lessons (group_id, day_of_week, pair_number, subject, teacher, room) VALUES (?, ?, ?, ?, ?, ?)');
            foreach ($lessons as $lesson) {
                $insert->execute([$lesson['group_id'], $lesson['day'], $lesson['pair'], $lesson['subject'], $lesson['teacher'], $lesson['room']]);
            }
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
        Auth::log('import', 'schedule', '', ['rows' => \count($lessons), 'days' => \count($combos), 'file' => $file['name']]);
        Http::json([
            'ok' => true, 'imported' => \count($lessons), 'days' => \count($combos),
            'message' => 'Импортировано занятий: ' . \count($lessons) . '. Обновлено расписаний на дни: ' . \count($combos) . '.',
        ]);
    }

    public function template(): never
    {
        Auth::require('schedule');
        $csv = "\xEF\xBB\xBF" . "Группа;День;№ пары;Предмет;Преподаватель;Аудитория\n";
        $csv .= "101ИССС;Понедельник;1;Математика;Иванова И.И.;305\n";
        \header('Content-Type: text/csv; charset=utf-8');
        \header('Content-Disposition: attachment; filename="ktits-schedule-template.csv"');
        echo $csv;
        exit;
    }

    public function itcubeGet(): void
    {
        Auth::require('schedule');
        $day = Validator::id($_GET['day'] ?? 0);
        if ($day > 6) {
            Http::error('День недели должен быть от 1 до 6.');
        }
        $stmt = $this->pdo()->prepare('SELECT id, start_time, end_time, room, subject, teacher, group_name FROM itcube_lessons WHERE day_of_week = ? ORDER BY start_time, sort_order');
        $stmt->execute([$day]);
        Http::json(['ok' => true, 'rows' => \array_map(static fn ($row) => [
            'id' => (int)$row['id'],
            'start' => \substr($row['start_time'], 0, 5),
            'end' => \substr($row['end_time'], 0, 5),
            'room' => $row['room'], 'subject' => $row['subject'],
            'teacher' => $row['teacher'], 'group' => $row['group_name'],
        ], $stmt->fetchAll())]);
    }

    public function itcubeSave(): void
    {
        Auth::require('schedule');
        Auth::requireCsrf();
        $input = Http::input();
        $day = Validator::id($input['day'] ?? 0);
        if ($day > 6) {
            Http::error('День недели должен быть от 1 до 6.');
        }
        $rows = $input['rows'] ?? null;
        if (!\is_array($rows) || \count($rows) > 24) {
            Http::error('Передайте не более 24 занятий.');
        }
        $prepared = [];
        foreach (\array_values($rows) as $row) {
            if (!\is_array($row)) {
                Http::error('Некорректная строка расписания.');
            }
            $start = Validator::time((string)($row['start'] ?? ''));
            $end = Validator::time((string)($row['end'] ?? ''));
            if (\strtotime($end) <= \strtotime($start)) {
                Http::error('Время окончания занятия должно быть позже времени начала.');
            }
            $prepared[] = [
                'start' => $start, 'end' => $end,
                'room' => Validator::clean($row['room'] ?? '', 60),
                'subject' => Validator::clean($row['subject'] ?? '', 255),
                'teacher' => Validator::clean($row['teacher'] ?? '', 255),
                'group' => Validator::clean($row['group'] ?? '', 120),
            ];
        }
        $pdo = $this->pdo();
        $pdo->beginTransaction();
        try {
            $pdo->prepare('DELETE FROM itcube_lessons WHERE day_of_week = ?')->execute([$day]);
            $insert = $pdo->prepare('INSERT INTO itcube_lessons (day_of_week, start_time, end_time, room, subject, teacher, group_name, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
            foreach ($prepared as $index => $row) {
                $insert->execute([$day, $row['start'], $row['end'], $row['room'], $row['subject'], $row['teacher'], $row['group'], $index]);
            }
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
        Auth::log('save', 'itcube', (string)$day, ['rows' => \count($rows)]);
        Http::json(['ok' => true, 'message' => 'Расписание IT-CUBE сохранено и уже доступно на киоске.']);
    }
}
