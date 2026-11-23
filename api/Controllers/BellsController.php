<?php
declare(strict_types=1);

namespace Ktits\Controllers;

use Ktits\Core\Auth;
use Ktits\Core\Database;
use Ktits\Core\Http;
use Ktits\Core\Validator;
use PDO;

final class BellsController
{
    private function pdo(): PDO
    {
        return Database::pdo();
    }

    public function get(): void
    {
        Auth::require('schedule');
        $rows = $this->pdo()->query('SELECT * FROM bell_schedules ORDER BY day_type, is_short, pair_number')->fetchAll();
        Http::json(['ok' => true, 'rows' => \array_map(static fn ($row) => [
            'id' => (int)$row['id'], 'day_type' => $row['day_type'], 'is_short' => (bool)$row['is_short'],
            'pair_number' => (int)$row['pair_number'], 'start' => \substr($row['start_time'], 0, 5),
            'end' => \substr($row['end_time'], 0, 5), 'break_text' => $row['break_text'],
            'is_active' => (bool)$row['is_active'],
        ], $rows)]);
    }

    public function save(): void
    {
        Auth::require('schedule');
        Auth::requireCsrf();
        $input = Http::input();
        $dayType = (string)($input['day_type'] ?? '');
        if (!\in_array($dayType, ['week', 'sat'], true)) {
            Http::error('Некорректный тип дня.');
        }
        $isShort = !empty($input['is_short']) ? 1 : 0;
        $activate = !empty($input['is_active']) ? 1 : 0;
        $rows = $input['rows'] ?? null;
        if (!\is_array($rows) || !$rows || \count($rows) > 8) {
            Http::error('Добавьте от 1 до 8 пар.');
        }
        $pdo = $this->pdo();
        $pdo->beginTransaction();
        try {
            $pdo->prepare('DELETE FROM bell_schedules WHERE day_type = ? AND is_short = ?')->execute([$dayType, $isShort]);
            $insert = $pdo->prepare('INSERT INTO bell_schedules (day_type, is_short, pair_number, start_time, end_time, break_text, is_active) VALUES (?, ?, ?, ?, ?, ?, ?)');
            foreach (\array_values($rows) as $index => $row) {
                $start = Validator::time((string)($row['start'] ?? ''));
                $end = Validator::time((string)($row['end'] ?? ''));
                if (\strtotime($end) <= \strtotime($start)) {
                    throw new \InvalidArgumentException('Время окончания пары должно быть позже времени начала.');
                }
                $insert->execute([$dayType, $isShort, $index + 1, $start, $end, Validator::clean($row['break_text'] ?? '', 30), $activate]);
            }
            if ($activate) {
                $pdo->prepare('UPDATE bell_schedules SET is_active = 0 WHERE day_type = ? AND is_short <> ?')->execute([$dayType, $isShort]);
            }
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            if ($e instanceof \InvalidArgumentException) {
                Http::error($e->getMessage());
            }
            throw $e;
        }
        Auth::log('save', 'bells', $dayType . ':' . $isShort, ['rows' => \count($rows), 'active' => $activate]);
        Http::json(['ok' => true, 'message' => 'Расписание звонков сохранено.']);
    }

    public function updateTime(): void
    {
        Auth::require('schedule');
        Auth::requireCsrf();
        $input = Http::input();
        $id = Validator::id($input['id'] ?? 0);
        $start = Validator::time((string)($input['start'] ?? ''));
        $end = Validator::time((string)($input['end'] ?? ''));
        if (\strtotime($end) <= \strtotime($start)) {
            Http::error('Время окончания пары должно быть позже времени начала.');
        }
        $stmt = $this->pdo()->prepare('UPDATE bell_schedules SET start_time = ?, end_time = ? WHERE id = ?');
        $stmt->execute([$start, $end, $id]);
        if (!$stmt->rowCount() && !$this->bellExists($id)) {
            Http::error('Пара звонков не найдена.', 404);
        }
        Auth::log('save', 'bells-time', (string)$id, ['start' => $start, 'end' => $end]);
        Http::json(['ok' => true, 'message' => 'Время пары обновлено.']);
    }

    private function bellExists(int $id): bool
    {
        $stmt = $this->pdo()->prepare('SELECT id FROM bell_schedules WHERE id = ?');
        $stmt->execute([$id]);
        return (bool)$stmt->fetch();
    }
}
