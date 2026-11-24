<?php
declare(strict_types=1);

use Ktits\Core\ApiException;
use Ktits\Services\SpreadsheetReader;

if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit('CLI only');
}

require __DIR__ . '/../../api/Core/ApiException.php';
require __DIR__ . '/../../api/Services/SpreadsheetReader.php';

$file = $argv[1] ?? '';
if ($file === '' || !is_file($file)) {
    fwrite(STDERR, "Использование: php tools/scripts/import_itcube.php <файл.xlsx>\n");
    exit(1);
}

$days = [
    'понедельник' => 1, 'вторник' => 2, 'среда' => 3,
    'четверг' => 4, 'пятница' => 5, 'суббота' => 6,
];

$roomByColumn = [
    0 => '',           // колонка A — кабинет не указан
    3 => '301', 4 => '302', 5 => '304', 6 => '305',
    7 => '308', 8 => '309', 9 => '311', 10 => 'коворкинг',
];

function normalizeTime(string $value): string
{
    $value = str_replace('.', ':', $value);
    return str_pad($value, 5, '0', STR_PAD_LEFT);
}

function parseCell(string $raw, string $slotStart, string $slotEnd): array
{
    $text = trim(preg_replace('/\s+/u', ' ', $raw));
    $start = $slotStart;
    $end = $slotEnd;
    if (preg_match('/^(\d{1,2}[:.]\d{2})\s*[-–]\s*(\d{1,2}[:.]\d{2})\s*(.*)$/u', $text, $m)) {
        $start = normalizeTime($m[1]);
        $end = normalizeTime($m[2]);
        $text = trim($m[3]);
    }
    $text = preg_replace('/([А-ЯЁ]\.)(\d)/u', '$1 $2', $text);
    $teacher = '';
    $group = '';
    $subject = '';
    if ($text !== '') {
        $tokens = preg_split('/\s+/u', $text);
        $last = end($tokens);
        $initials = (bool)preg_match('/^[А-ЯЁ]\.[А-ЯЁ]\.?$/u', $last);
        $groupIndex = null;
        foreach ($tokens as $i => $token) {
            if (preg_match('/\d/u', $token)) {
                $groupIndex = $i;
                break;
            }
        }
        if ($groupIndex === null) {
            $subject = $text;
        } elseif ($initials) {
            $group = $tokens[0];
            $teacher = trim(implode(' ', array_slice($tokens, 1)));
        } else {
            $group = implode('', array_slice($tokens, $groupIndex));
            $teacher = trim(preg_replace('/([а-яё])([А-ЯЁ])/u', '$1 $2', implode(' ', array_slice($tokens, 0, $groupIndex))));
        }
    }
    return [$start, $end, $teacher, $group, $subject];
}

try {
    $rows = SpreadsheetReader::read($file, basename($file));
} catch (ApiException $e) {
    fwrite(STDERR, 'Ошибка чтения файла: ' . $e->getMessage() . "\n");
    exit(1);
}

$lessons = [];
$day = 0;
foreach ($rows as $row) {
    $dayCell = mb_strtolower(trim((string)($row[1] ?? '')));
    if (isset($days[$dayCell])) {
        $day = $days[$dayCell];
    }
    if ($day === 0) continue;

    $slot = trim((string)($row[2] ?? ''));
    $slotStart = '';
    $slotEnd = '';
    if (preg_match('/(\d{1,2}[:.]\d{2})\s*[-–]\s*(\d{1,2}[:.]\d{2})/u', $slot, $m)) {
        $slotStart = normalizeTime($m[1]);
        $slotEnd = normalizeTime($m[2]);
    }

    foreach ($roomByColumn as $index => $room) {
        $raw = trim((string)($row[$index] ?? ''));
        if ($raw === '' || $index === 1 || $index === 2) continue;
        if ($slotStart === '') continue;
        [$start, $end, $teacher, $group, $subject] = parseCell($raw, $slotStart, $slotEnd);
        $lessons[] = [$day, $start, $end, $room, $subject, $teacher, $group];
    }
}

if (!$lessons) {
    fwrite(STDERR, "В файле не найдено занятий IT-CUBE.\n");
    exit(1);
}

$pdo = new PDO(
    'mysql:host=' . (getenv('KTITS_DB_HOST') ?: '127.0.0.1')
    . ';port=' . (getenv('KTITS_DB_PORT') ?: 3306)
    . ';dbname=' . (getenv('KTITS_DB_NAME') ?: 'ktits_info') . ';charset=utf8mb4',
    getenv('KTITS_DB_USER') ?: 'root',
    getenv('KTITS_DB_PASS') ?: '',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$pdo->beginTransaction();
try {
    $pdo->exec('DELETE FROM itcube_lessons');
    $insert = $pdo->prepare('INSERT INTO itcube_lessons (day_of_week, start_time, end_time, room, subject, teacher, group_name, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
    foreach ($lessons as $i => $lesson) {
        $insert->execute([$lesson[0], $lesson[1] . ':00', $lesson[2] . ':00', $lesson[3], $lesson[4], $lesson[5], $lesson[6], $i]);
    }
    $pdo->commit();
} catch (Throwable $e) {
    $pdo->rollBack();
    fwrite(STDERR, 'Ошибка записи в базу: ' . $e->getMessage() . "\n");
    exit(1);
}

echo 'Импортировано занятий: ' . count($lessons) . "\n";
