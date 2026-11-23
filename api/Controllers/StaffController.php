<?php
declare(strict_types=1);

namespace Ktits\Controllers;

use Ktits\Core\Auth;
use Ktits\Core\Database;
use Ktits\Core\Http;
use Ktits\Core\Validator;
use PDO;

final class StaffController
{
    private const CATEGORIES = ['teachers', 'management', 'departments', 'itcube'];

    private function pdo(): PDO
    {
        return Database::pdo();
    }

    private function row(array $row): array
    {
        return [
            'id' => (int)$row['id'], 'category' => $row['category'], 'full_name' => $row['full_name'],
            'position' => $row['position'], 'qualification' => $row['qualification'], 'room' => $row['room'],
            'department_head' => $row['department_head'], 'description' => $row['description'],
            'photo_path' => $row['photo_path'], 'is_head' => (bool)$row['is_head'],
            'sort_order' => (int)$row['sort_order'], 'is_active' => (bool)$row['is_active'],
        ];
    }

    public function get(): void
    {
        Auth::require('content');
        $rows = $this->pdo()->query('SELECT * FROM staff ORDER BY category, sort_order, id')->fetchAll();
        Http::json(['ok' => true, 'staff' => \array_map($this->row(...), $rows)]);
    }

    public function save(?int $id = null): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $input = Http::input();
        $category = (string)($input['category'] ?? '');
        if (!\in_array($category, self::CATEGORIES, true)) {
            Http::error('Некорректная категория сотрудника.');
        }
        $name = Validator::requireString($input, 'full_name', 250);
        $position = Validator::requireString($input, 'position', 2000);
        $values = [
            $category, $name, $position,
            Validator::clean($input['qualification'] ?? '', 120),
            Validator::clean($input['room'] ?? '', 60),
            Validator::clean($input['department_head'] ?? '', 180),
            Validator::clean($input['description'] ?? '', 500),
            Validator::clean($input['photo_path'] ?? '', 255),
            !empty($input['is_head']) ? 1 : 0,
            !empty($input['is_active']) ? 1 : 0,
        ];
        if ($id === null) {
            $sort = (int)$this->pdo()->query('SELECT COALESCE(MAX(sort_order), 0) + 1 FROM staff')->fetchColumn();
            $stmt = $this->pdo()->prepare('INSERT INTO staff (category, full_name, position, qualification, room, department_head, description, photo_path, is_head, is_active, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
            $stmt->execute(\array_merge($values, [$sort]));
            $id = (int)$this->pdo()->lastInsertId();
            $action = 'create';
        } else {
            $stmt = $this->pdo()->prepare('UPDATE staff SET category=?, full_name=?, position=?, qualification=?, room=?, department_head=?, description=?, photo_path=?, is_head=?, is_active=? WHERE id=?');
            $stmt->execute(\array_merge($values, [$id]));
            $action = 'update';
        }
        Auth::log($action, 'staff', $id);
        $stmt = $this->pdo()->prepare('SELECT * FROM staff WHERE id = ?');
        $stmt->execute([$id]);
        Http::json(['ok' => true, 'staff' => $this->row($stmt->fetch()), 'message' => 'Данные сотрудника сохранены.'], $action === 'create' ? 201 : 200);
    }

    public function delete(int $id): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $stmt = $this->pdo()->prepare('DELETE FROM staff WHERE id = ?');
        $stmt->execute([$id]);
        if (!$stmt->rowCount()) {
            Http::error('Сотрудник не найден.', 404);
        }
        Auth::log('delete', 'staff', $id);
        Http::json(['ok' => true, 'message' => 'Сотрудник удалён.']);
    }
}
