<?php
declare(strict_types=1);

namespace Ktits\Controllers;

use Ktits\Core\ApiException;
use Ktits\Core\Auth;
use Ktits\Core\Database;
use Ktits\Core\Http;
use Ktits\Core\Validator;
use PDO;

final class PracticeController
{
    private function pdo(): PDO
    {
        return Database::pdo();
    }

    public function get(): void
    {
        Auth::require('schedule');
        $pdo = $this->pdo();
        $rows = $pdo->query(
            'SELECT b.*, g.code AS group_code, g.course FROM practice_blocks b '
            . 'JOIN `groups` g ON g.id = b.group_id ORDER BY b.sort_order, b.id'
        )->fetchAll();
        $lessons = $pdo->query(
            'SELECT id, block_id, lesson_date, pair_number, room FROM practice_lessons '
            . 'ORDER BY block_id, lesson_date, pair_number, id'
        )->fetchAll();
        $byBlock = [];
        foreach ($lessons as $lesson) {
            $byBlock[(int)$lesson['block_id']][] = [
                'id' => (int)$lesson['id'],
                'date' => $lesson['lesson_date'],
                'pair' => (int)$lesson['pair_number'],
                'room' => $lesson['room'],
            ];
        }
        $blocks = \array_map(static fn(array $row) => [
            'id' => (int)$row['id'],
            'group_id' => (int)$row['group_id'],
            'group' => $row['group_code'],
            'course' => (int)$row['course'],
            'module' => $row['module'],
            'specialty' => $row['specialty'],
            'subgroup' => $row['subgroup'],
            'teacher' => $row['teacher'],
            'date_start' => $row['date_start'],
            'date_end' => $row['date_end'],
            'sort_order' => (int)$row['sort_order'],
            'is_active' => (bool)$row['is_active'],
            'lessons' => $byBlock[(int)$row['id']] ?? [],
        ], $rows);
        Http::json(['ok' => true, 'blocks' => $blocks]);
    }

    public function create(): void
    {
        Auth::require('schedule');
        Auth::requireCsrf();
        $input = Http::input();
        $data = $this->validateBlock($input);
        $lessons = $this->validateLessons($input['lessons'] ?? null, $data['date_start'], $data['date_end']);
        $pdo = $this->pdo();
        $sortOrder = self::sortOrder($input['sort_order'] ?? null);
        if ($sortOrder === null) {
            $sortOrder = (int)$pdo->query('SELECT COALESCE(MAX(sort_order), 0) + 1 FROM practice_blocks')->fetchColumn();
        }
        $pdo->beginTransaction();
        try {
            $stmt = $pdo->prepare(
                'INSERT INTO practice_blocks '
                . '(group_id, module, specialty, subgroup, teacher, date_start, date_end, sort_order, is_active) '
                . 'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->execute([
                $data['group_id'], $data['module'], $data['specialty'], $data['subgroup'], $data['teacher'],
                $data['date_start'], $data['date_end'], $sortOrder, !empty($input['is_active']) || !isset($input['is_active']) ? 1 : 0,
            ]);
            $newId = (int)$pdo->lastInsertId();
            $this->replaceLessons($pdo, $newId, $lessons);
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
        Auth::log('create', 'practice_block', $newId, ['group_id' => $data['group_id'], 'lessons' => \count($lessons)]);
        Http::json(['ok' => true, 'id' => $newId, 'message' => 'Блок практики создан и уже доступен на киоске.']);
    }

    public function save(int $id): void
    {
        Auth::require('schedule');
        Auth::requireCsrf();
        $current = $this->blockById($id);
        $input = Http::input();
        $data = $this->validateBlock($input);
        $lessons = $this->validateLessons($input['lessons'] ?? null, $data['date_start'], $data['date_end']);
        $sortOrder = self::sortOrder($input['sort_order'] ?? null) ?? (int)$current['sort_order'];
        $isActive = isset($input['is_active']) ? (!empty($input['is_active']) ? 1 : 0) : (int)$current['is_active'];
        $pdo = $this->pdo();
        $pdo->beginTransaction();
        try {
            $pdo->prepare(
                'UPDATE practice_blocks SET group_id = ?, module = ?, specialty = ?, subgroup = ?, teacher = ?, '
                . 'date_start = ?, date_end = ?, sort_order = ?, is_active = ? WHERE id = ?'
            )->execute([
                $data['group_id'], $data['module'], $data['specialty'], $data['subgroup'], $data['teacher'],
                $data['date_start'], $data['date_end'], $sortOrder, $isActive, $id,
            ]);
            $this->replaceLessons($pdo, $id, $lessons);
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
        Auth::log('save', 'practice_block', $id, ['group_id' => $data['group_id'], 'lessons' => \count($lessons)]);
        Http::json(['ok' => true, 'message' => 'Блок практики сохранён и уже доступен на киоске.']);
    }

    public function delete(int $id): void
    {
        Auth::require('schedule');
        Auth::requireCsrf();
        $block = $this->blockById($id);
        $this->pdo()->prepare('DELETE FROM practice_blocks WHERE id = ?')->execute([$id]);
        Auth::log('delete', 'practice_block', $id, ['group_id' => (int)$block['group_id']]);
        Http::json(['ok' => true, 'message' => 'Блок практики удалён.']);
    }

    private function blockById(int $id): array
    {
        $stmt = $this->pdo()->prepare('SELECT * FROM practice_blocks WHERE id = ?');
        $stmt->execute([$id]);
        $block = $stmt->fetch();
        if (!$block) {
            Http::error('Блок практики не найден.', 404);
        }
        return $block;
    }

    private function validateBlock(array $input): array
    {
        $groupId = Validator::id($input['group_id'] ?? 0);
        $stmt = $this->pdo()->prepare('SELECT id FROM `groups` WHERE id = ?');
        $stmt->execute([$groupId]);
        if (!$stmt->fetch()) {
            Http::error('Группа не найдена.', 404);
        }
        $module = Validator::requireString($input, 'module', 180);
        $specialty = Validator::requireString($input, 'specialty', 180);
        $dateStart = Validator::date((string)($input['date_start'] ?? ''));
        $dateEnd = Validator::date((string)($input['date_end'] ?? ''));
        if ($dateStart > $dateEnd) {
            throw new ApiException('Дата окончания не может быть раньше даты начала.');
        }
        if ((new \DateTime($dateStart))->diff(new \DateTime($dateEnd))->days > 366) {
            throw new ApiException('Период практики не должен превышать 366 дней.');
        }
        return [
            'group_id' => $groupId,
            'module' => $module,
            'specialty' => $specialty,
            'subgroup' => Validator::clean($input['subgroup'] ?? '', 60),
            'teacher' => Validator::clean($input['teacher'] ?? '', 120),
            'date_start' => $dateStart,
            'date_end' => $dateEnd,
        ];
    }

    private function validateLessons(mixed $rows, string $dateStart, string $dateEnd): array
    {
        if (!\is_array($rows) || !$rows || \count($rows) > 2562) {
            throw new ApiException('Передайте полную сетку уроков: даты блока и пары 1–7.');
        }
        $result = [];
        $byDate = [];
        foreach ($rows as $row) {
            if (!\is_array($row)) {
                throw new ApiException('Некорректная строка сетки уроков.');
            }
            $date = Validator::date((string)($row['date'] ?? ''));
            if ($date < $dateStart || $date > $dateEnd) {
                throw new ApiException('Дата урока выходит за период практики.');
            }
            $pair = \filter_var($row['pair'] ?? null, FILTER_VALIDATE_INT);
            if ($pair === false || $pair < 1 || $pair > 7) {
                throw new ApiException('Номер пары должен быть от 1 до 7.');
            }
            if (isset($byDate[$date][$pair])) {
                throw new ApiException('В сетке есть повторяющиеся ячейки даты и пары.');
            }
            $byDate[$date][$pair] = true;
            $result[] = ['date' => $date, 'pair' => $pair, 'room' => Validator::clean($row['room'] ?? '', 30)];
        }
        foreach ($byDate as $date => $pairs) {
            if (\count($pairs) !== 7) {
                throw new ApiException('Для каждой даты должны быть все пары с 1 по 7, включая пустые.');
            }
        }
        \usort($result, static fn(array $a, array $b) => [$a['date'], $a['pair']] <=> [$b['date'], $b['pair']]);
        return $result;
    }

    private function replaceLessons(PDO $pdo, int $blockId, array $lessons): void
    {
        $pdo->prepare('DELETE FROM practice_lessons WHERE block_id = ?')->execute([$blockId]);
        $insert = $pdo->prepare('INSERT INTO practice_lessons (block_id, lesson_date, pair_number, room) VALUES (?, ?, ?, ?)');
        foreach ($lessons as $lesson) {
            $insert->execute([$blockId, $lesson['date'], $lesson['pair'], $lesson['room']]);
        }
    }

    private static function sortOrder(mixed $value): ?int
    {
        if ($value === null || $value === '') {
            return null;
        }
        $sortOrder = \filter_var($value, FILTER_VALIDATE_INT);
        if ($sortOrder === false || $sortOrder < 0 || $sortOrder > 100000) {
            throw new ApiException('Порядок сортировки должен быть целым числом от 0 до 100000.');
        }
        return $sortOrder;
    }
}
