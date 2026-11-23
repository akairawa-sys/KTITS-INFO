<?php
declare(strict_types=1);

namespace Ktits\Controllers;

use Ktits\Core\Auth;
use Ktits\Core\Database;
use Ktits\Core\Http;
use Ktits\Core\Validator;
use PDO;

final class PostsController
{
    private const KINDS = ['news', 'events'];

    private function pdo(): PDO
    {
        return Database::pdo();
    }

    private function kind(string $kind): string
    {
        if (!\in_array($kind, self::KINDS, true)) {
            Http::error('Неизвестный тип публикации.', 404);
        }
        return $kind;
    }

    public function get(string $kind): void
    {
        Auth::require('content');
        $kind = $this->kind($kind);
        $order = $kind === 'news' ? 'published_at DESC, id DESC' : 'event_date DESC, id DESC';
        $rows = $this->pdo()->query("SELECT * FROM {$kind} ORDER BY {$order}")->fetchAll();
        Http::json(['ok' => true, 'items' => \array_map(static function ($row) use ($kind) {
            $item = [
                'id' => (int)$row['id'], 'title' => $row['title'], 'status' => $row['status'],
                'image_path' => $row['image_path'], 'description' => $kind === 'events' ? ($row['description'] ?? '') : ($row['content'] ?? ''),
            ];
            if ($kind === 'news') {
                $item += ['category' => $row['category'], 'summary' => $row['summary'], 'published_at' => $row['published_at']];
            } else {
                $item += ['summary' => $row['description'] ?? '', 'event_date' => $row['event_date'], 'event_time' => $row['event_time'] ? \substr($row['event_time'], 0, 5) : '', 'place' => $row['place'], 'room_key' => $row['room_key']];
            }
            return $item;
        }, $rows)]);
    }

    public function save(string $kind, ?int $id = null): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $kind = $this->kind($kind);
        $input = Http::input();
        $title = Validator::requireString($input, 'title', 255);
        $status = (string)($input['status'] ?? 'draft');
        if (!\in_array($status, ['draft', 'published'], true)) {
            Http::error('Некорректный статус публикации.');
        }
        $image = Validator::clean($input['image_path'] ?? '', 255);
        if ($kind === 'news') {
            $category = Validator::requireString($input, 'category', 100);
            $summary = Validator::requireString($input, 'summary', 5000);
            $content = Validator::clean($input['description'] ?? '', 10000);
            $date = Validator::date((string)($input['published_at'] ?? ''));
            $fields = 'category=?, title=?, summary=?, content=?, published_at=?, image_path=?, status=?';
            $values = [$category, $title, $summary, $content, $date, $image, $status];
        } else {
            $description = Validator::clean($input['description'] ?? ($input['summary'] ?? ''), 10000);
            $date = Validator::date((string)($input['event_date'] ?? ''));
            $time = !empty($input['event_time']) ? Validator::time((string)$input['event_time']) : null;
            $place = Validator::clean($input['place'] ?? '', 255);
            $roomKey = Validator::clean($input['room_key'] ?? '', 100);
            $fields = 'title=?, description=?, event_date=?, event_time=?, place=?, image_path=?, room_key=?, status=?';
            $values = [$title, $description, $date, $time, $place, $image, $roomKey, $status];
        }
        if ($id === null) {
            $stmt = $this->pdo()->prepare("INSERT INTO {$kind} SET {$fields}");
            $stmt->execute($values);
            $id = (int)$this->pdo()->lastInsertId();
            $action = 'create';
        } else {
            $stmt = $this->pdo()->prepare("UPDATE {$kind} SET {$fields} WHERE id = ?");
            $stmt->execute(\array_merge($values, [$id]));
            $action = 'update';
        }
        if ($kind === 'news') {
            $this->pdo()->prepare("INSERT INTO settings (setting_key, setting_value) VALUES ('news_updated_at', ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)")
                ->execute([\date('d.m.Y')]);
        }
        Auth::log($action, $kind, $id);
        Http::json(['ok' => true, 'id' => $id, 'message' => 'Публикация сохранена.'], $action === 'create' ? 201 : 200);
    }

    public function delete(string $kind, int $id): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $kind = $this->kind($kind);
        $stmt = $this->pdo()->prepare("DELETE FROM {$kind} WHERE id = ?");
        $stmt->execute([$id]);
        if (!$stmt->rowCount()) {
            Http::error('Публикация не найдена.', 404);
        }
        Auth::log('delete', $kind, $id);
        Http::json(['ok' => true, 'message' => 'Публикация удалена.']);
    }
}
