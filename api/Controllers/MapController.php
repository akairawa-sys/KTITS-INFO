<?php
declare(strict_types=1);

namespace Ktits\Controllers;

use Ktits\Core\Auth;
use Ktits\Core\ApiException;
use Ktits\Core\Database;
use Ktits\Core\Http;
use Ktits\Core\Validator;
use PDO;

final class MapController
{
    private const TYPES = ['aud', 'service', 'stairs'];

    private const CANVAS_W = 1240;
    private const CANVAS_H = 720;
    private const INNER_X = 40;
    private const INNER_W = 1160;
    private const ROW_GAP = 12;

    private function pdo(): PDO
    {
        return Database::pdo();
    }

    public function get(): void
    {
        Auth::require('content');
        $pdo = $this->pdo();
        $floors = $pdo->query('SELECT * FROM floors ORDER BY sort_order, id')->fetchAll();
        $roomStmt = $pdo->prepare('SELECT * FROM rooms WHERE floor_id = ? ORDER BY sort_order, id');
        $nodeStmt = $pdo->prepare('SELECT * FROM route_nodes WHERE floor_id = ? ORDER BY id');
        $edgeStmt = $pdo->prepare('SELECT e.node_a, e.node_b FROM route_edges e JOIN route_nodes n ON n.id = e.node_a WHERE n.floor_id = ? ORDER BY e.node_a, e.node_b');
        $result = [];
        foreach ($floors as $floor) {
            $roomStmt->execute([$floor['id']]);
            $rooms = [];
            $mode = 'free';
            foreach ($roomStmt->fetchAll() as $room) {
                if ($room['row_index'] !== null) {
                    $mode = 'rows';
                }
                $rooms[] = $this->roomRow($room);
            }
            $nodeStmt->execute([$floor['id']]);
            $nodes = \array_map(fn(array $node) => $this->nodeRow($node), $nodeStmt->fetchAll());
            $edgeStmt->execute([$floor['id']]);
            $edges = \array_map(static fn(array $edge) => [
                'node_a' => (int)$edge['node_a'],
                'node_b' => (int)$edge['node_b'],
            ], $edgeStmt->fetchAll());
            $result[] = [
                'id' => (int)$floor['id'],
                'floor_key' => $floor['floor_key'],
                'button_label' => $floor['button_label'],
                'short_title' => $floor['short_title'],
                'title' => $floor['title'],
                'mode' => $mode,
                'underlay_path' => $floor['underlay_path'],
                'underlay_opacity' => (float)$floor['underlay_opacity'],
                'underlay_scale' => (float)$floor['underlay_scale'],
                'rooms' => $rooms,
                'route_nodes' => $nodes,
                'route_edges' => $edges,
            ];
        }
        Http::json(['ok' => true, 'floors' => $result]);
    }

    public function create(): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $input = Http::input();
        $floorId = Validator::id($input['floor_id'] ?? 0);
        $floor = $this->floorById($floorId);
        if ($this->floorMode($floorId) === 'rows') {
            throw new ApiException('Этаж в «строчной» планировке. Сначала переведите его в свободную.');
        }
        $roomKey = self::roomKey((string)($input['room_key'] ?? ''));
        $name = Validator::requireString($input, 'name', 255);
        $type = self::roomType((string)($input['type'] ?? ''));
        $coords = self::coords($input, ['x' => 545, 'y' => 300, 'w' => 150, 'h' => 120]);

        $pdo = $this->pdo();
        $dup = $pdo->prepare('SELECT COUNT(*) FROM rooms WHERE floor_id = ? AND room_key = ?');
        $dup->execute([$floorId, $roomKey]);
        if ((int)$dup->fetchColumn() > 0) {
            throw new ApiException('Помещение с таким кодом уже есть на этом этаже.');
        }
        $sort = (int)$pdo->query('SELECT COALESCE(MAX(sort_order), 0) FROM rooms WHERE floor_id = ' . $floorId)->fetchColumn();
        $stmt = $pdo->prepare('INSERT INTO rooms (floor_id, room_key, name, type, x, y, w, h, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)');
        $stmt->execute([$floorId, $roomKey, $name, $type, $coords['x'], $coords['y'], $coords['w'], $coords['h'], $sort + 1]);
        $newId = (int)$pdo->lastInsertId();
        Auth::log('create', 'map_room', $newId, ['floor' => $floor['floor_key'], 'room_key' => $roomKey]);
        Http::json(['ok' => true, 'id' => $newId, 'message' => 'Помещение добавлено на схему.']);
    }

    public function save(int $id): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $input = Http::input();
        $room = $this->roomById($id);
        if ($room['row_index'] !== null) {
            throw new ApiException('Этаж в «строчной» планировке. Сначала переведите его в свободную.');
        }
        $name = Validator::requireString($input, 'name', 255);
        $type = self::roomType((string)($input['type'] ?? ''));
        $coords = self::coords($input, ['x' => $room['x'], 'y' => $room['y'], 'w' => $room['w'], 'h' => $room['h']]);
        $roomKey = self::roomKey((string)($input['room_key'] ?? $room['room_key']));
        if ($roomKey !== $room['room_key']) {
            $dup = $this->pdo()->prepare('SELECT COUNT(*) FROM rooms WHERE floor_id = ? AND room_key = ? AND id <> ?');
            $dup->execute([$room['floor_id'], $roomKey, $id]);
            if ((int)$dup->fetchColumn() > 0) {
                throw new ApiException('Помещение с таким кодом уже есть на этом этаже.');
            }
        }

        $this->pdo()->prepare('UPDATE rooms SET room_key = ?, name = ?, type = ?, x = ?, y = ?, w = ?, h = ? WHERE id = ?')
            ->execute([$roomKey, $name, $type, $coords['x'], $coords['y'], $coords['w'], $coords['h'], $id]);
        Auth::log('save', 'map_room', $id, ['room_key' => $room['room_key']]);
        Http::json(['ok' => true, 'message' => 'Помещение сохранено.']);
    }

    public function delete(int $id): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $room = $this->roomById($id);
        $this->pdo()->prepare('DELETE FROM rooms WHERE id = ?')->execute([$id]);
        Auth::log('delete', 'map_room', $id, ['room_key' => $room['room_key']]);
        Http::json(['ok' => true, 'message' => 'Помещение удалено со схемы.']);
    }

    public function convert(): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $input = Http::input();
        $floorId = Validator::id($input['floor_id'] ?? 0);
        $floor = $this->floorById($floorId);
        if ($this->floorMode($floorId) !== 'rows') {
            throw new ApiException('Этот этаж уже в свободной планировке.');
        }

        $pdo = $this->pdo();
        $stmt = $pdo->prepare('SELECT * FROM rooms WHERE floor_id = ? ORDER BY row_index, sort_order, id');
        $stmt->execute([$floorId]);
        $rows = [];
        foreach ($stmt->fetchAll() as $room) {
            $rows[(int)$room['row_index']][] = $room;
        }

        $update = $pdo->prepare('UPDATE rooms SET x = ?, y = ?, w = ?, h = ?, row_index = NULL, row_y = NULL, row_height = NULL, weight = NULL WHERE id = ?');
        $pdo->beginTransaction();
        try {
            foreach ($rows as $rooms) {
                $weights = \array_map(static fn ($room) => $room['weight'] !== null ? (float)$room['weight'] : 1.0, $rooms);
                $unit = (self::INNER_W - self::ROW_GAP * (\count($rooms) - 1)) / \array_sum($weights);
                $x = (float)self::INNER_X;
                foreach ($rooms as $index => $room) {
                    $w = $unit * $weights[$index];
                    $update->execute([
                        (int)\round($x),
                        (int)$room['row_y'],
                        (int)\round($w),
                        (int)$room['row_height'],
                        $room['id'],
                    ]);
                    $x += $w + self::ROW_GAP;
                }
            }
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }
        Auth::log('convert', 'map_floor', $floorId, ['floor' => $floor['floor_key'], 'rooms' => \count($rows) ? \array_sum(\array_map('count', $rows)) : 0]);
        Http::json(['ok' => true, 'message' => 'Этаж переведён в свободную планировку. Теперь помещения можно двигать мышью.']);
    }

    public function saveFloor(): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $input = Http::input();
        $floorId = Validator::id($input['floor_id'] ?? 0);
        $floor = $this->floorById($floorId);
        $path = \trim((string)($input['underlay_path'] ?? $floor['underlay_path']));
        if (\strlen($path) > 255 || ($path !== '' && !\preg_match('#^uploads/[A-Za-z0-9._-]+$#', $path))) {
            throw new ApiException('Подложка должна быть изображением, загруженным в папку uploads.');
        }
        $opacity = self::decimal($input['underlay_opacity'] ?? $floor['underlay_opacity'], 0, 1, 'прозрачность');
        $scale = self::decimal($input['underlay_scale'] ?? $floor['underlay_scale'], 0.1, 4, 'масштаб');
        $this->pdo()->prepare('UPDATE floors SET underlay_path = ?, underlay_opacity = ?, underlay_scale = ? WHERE id = ?')
            ->execute([$path, $opacity, $scale, $floorId]);
        Auth::log('save', 'map_floor', $floorId, ['floor' => $floor['floor_key'], 'underlay' => $path !== '']);
        Http::json(['ok' => true, 'message' => 'Настройки подложки сохранены.']);
    }

    public function createNode(): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $input = Http::input();
        $floorId = Validator::id($input['floor_id'] ?? 0);
        $floor = $this->floorById($floorId);
        [$x, $y] = self::nodeCoords($input, ['x' => 620, 'y' => 360]);
        $kind = self::nodeKind((string)($input['kind'] ?? 'corridor'));
        $roomKey = self::nullableRoomKey($input['room_key'] ?? null);
        $stmt = $this->pdo()->prepare('INSERT INTO route_nodes (floor_id, x, y, kind, room_key) VALUES (?, ?, ?, ?, ?)');
        $stmt->execute([$floorId, $x, $y, $kind, $roomKey]);
        $newId = (int)$this->pdo()->lastInsertId();
        Auth::log('create', 'map_route_node', $newId, ['floor' => $floor['floor_key'], 'kind' => $kind]);
        Http::json(['ok' => true, 'id' => $newId, 'message' => 'Узел добавлен. Выберите второй узел, чтобы создать ребро.']);
    }

    public function saveNode(int $id): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $input = Http::input();
        $node = $this->nodeById($id);
        [$x, $y] = self::nodeCoords($input, $node);
        $kind = self::nodeKind((string)($input['kind'] ?? $node['kind']));
        $roomKey = self::nullableRoomKey(\array_key_exists('room_key', $input) ? $input['room_key'] : $node['room_key']);
        $this->pdo()->prepare('UPDATE route_nodes SET x = ?, y = ?, kind = ?, room_key = ? WHERE id = ?')
            ->execute([$x, $y, $kind, $roomKey, $id]);
        Auth::log('save', 'map_route_node', $id, ['kind' => $kind]);
        Http::json(['ok' => true, 'message' => 'Узел сохранён.']);
    }

    public function deleteNode(int $id): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $this->nodeById($id);
        $this->pdo()->prepare('DELETE FROM route_nodes WHERE id = ?')->execute([$id]);
        Auth::log('delete', 'map_route_node', $id);
        Http::json(['ok' => true, 'message' => 'Узел и связанные рёбра удалены.']);
    }

    public function createEdge(): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $input = Http::input();
        [$a, $b] = $this->edgeNodes($input);
        $stmt = $this->pdo()->prepare('SELECT COUNT(*) FROM route_edges WHERE node_a = ? AND node_b = ?');
        $stmt->execute([$a, $b]);
        if ((int)$stmt->fetchColumn() > 0) {
            throw new ApiException('Эти узлы уже соединены.');
        }
        $this->pdo()->prepare('INSERT INTO route_edges (node_a, node_b) VALUES (?, ?)')->execute([$a, $b]);
        Auth::log('create', 'map_route_edge', $a . '-' . $b);
        Http::json(['ok' => true, 'message' => 'Узлы соединены.']);
    }

    public function deleteEdge(): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        [$a, $b] = $this->edgeNodes(Http::input());
        $stmt = $this->pdo()->prepare('DELETE FROM route_edges WHERE node_a = ? AND node_b = ?');
        $stmt->execute([$a, $b]);
        if ($stmt->rowCount() === 0) {
            throw new ApiException('Ребро не найдено.', 404);
        }
        Auth::log('delete', 'map_route_edge', $a . '-' . $b);
        Http::json(['ok' => true, 'message' => 'Ребро удалено.']);
    }

    private function roomRow(array $room): array
    {
        return [
            'id' => (int)$room['id'],
            'room_key' => $room['room_key'],
            'name' => $room['name'],
            'type' => $room['type'],
            'row_index' => $room['row_index'] !== null ? (int)$room['row_index'] : null,
            'row_y' => $room['row_y'] !== null ? (int)$room['row_y'] : null,
            'row_height' => $room['row_height'] !== null ? (int)$room['row_height'] : null,
            'weight' => $room['weight'] !== null ? (float)$room['weight'] : null,
            'x' => $room['x'] !== null ? (int)$room['x'] : null,
            'y' => $room['y'] !== null ? (int)$room['y'] : null,
            'w' => $room['w'] !== null ? (int)$room['w'] : null,
            'h' => $room['h'] !== null ? (int)$room['h'] : null,
        ];
    }

    private function nodeRow(array $node): array
    {
        return [
            'id' => (int)$node['id'],
            'floor_id' => (int)$node['floor_id'],
            'x' => (int)$node['x'],
            'y' => (int)$node['y'],
            'kind' => $node['kind'],
            'room_key' => $node['room_key'],
        ];
    }

    private function nodeById(int $id): array
    {
        $stmt = $this->pdo()->prepare('SELECT * FROM route_nodes WHERE id = ?');
        $stmt->execute([$id]);
        $node = $stmt->fetch();
        if (!$node) {
            throw new ApiException('Узел маршрутной сети не найден.', 404);
        }
        return $node;
    }

    private function edgeNodes(array $input): array
    {
        $a = Validator::id($input['node_a'] ?? 0);
        $b = Validator::id($input['node_b'] ?? 0);
        if ($a === $b) {
            throw new ApiException('Нельзя соединить узел с самим собой.');
        }
        $this->nodeById($a);
        $this->nodeById($b);
        return [\min($a, $b), \max($a, $b)];
    }

    private static function decimal(mixed $value, float $min, float $max, string $name): float
    {
        if (!\is_numeric($value)) {
            throw new ApiException('Некорректное значение параметра «' . $name . '».');
        }
        $number = (float)$value;
        if ($number < $min || $number > $max) {
            throw new ApiException('Параметр «' . $name . '» должен быть от ' . $min . ' до ' . $max . '.');
        }
        return $number;
    }

    private static function nodeCoords(array $input, array $defaults): array
    {
        $result = [];
        foreach (['x', 'y'] as $key) {
            $value = \filter_var($input[$key] ?? $defaults[$key], FILTER_VALIDATE_INT);
            if ($value === false || $value < 0 || $value > ($key === 'x' ? self::CANVAS_W : self::CANVAS_H)) {
                throw new ApiException('Координаты узла должны быть целыми числами в пределах схемы.');
            }
            $result[] = $value;
        }
        return $result;
    }

    private static function nodeKind(string $kind): string
    {
        if (!\in_array($kind, ['corridor', 'entrance', 'stairs', 'passage'], true)) {
            throw new ApiException('Некорректный тип узла.');
        }
        return $kind;
    }

    private static function nullableRoomKey(mixed $value): ?string
    {
        if ($value === null || \trim((string)$value) === '') {
            return null;
        }
        return self::roomKey((string)$value);
    }

    private function floorById(int $id): array
    {
        $stmt = $this->pdo()->prepare('SELECT * FROM floors WHERE id = ?');
        $stmt->execute([$id]);
        $floor = $stmt->fetch();
        if (!$floor) {
            throw new ApiException('Этаж не найден.', 404);
        }
        return $floor;
    }

    private function roomById(int $id): array
    {
        $stmt = $this->pdo()->prepare('SELECT * FROM rooms WHERE id = ?');
        $stmt->execute([$id]);
        $room = $stmt->fetch();
        if (!$room) {
            throw new ApiException('Помещение не найдено.', 404);
        }
        return $room;
    }

    private function floorMode(int $floorId): string
    {
        $stmt = $this->pdo()->prepare('SELECT COUNT(*) FROM rooms WHERE floor_id = ? AND row_index IS NOT NULL');
        $stmt->execute([$floorId]);
        return (int)$stmt->fetchColumn() > 0 ? 'rows' : 'free';
    }

    private static function roomKey(string $value): string
    {
        $value = \trim($value);
        if (!\preg_match('/^[A-Za-z0-9][A-Za-z0-9_-]{0,99}$/', $value)) {
            throw new ApiException('Код помещения: латинские буквы, цифры, дефис и подчёркивание (например, 305 или stairs-w).');
        }
        return $value;
    }

    private static function roomType(string $value): string
    {
        if (!\in_array($value, self::TYPES, true)) {
            throw new ApiException('Некорректный тип помещения.');
        }
        return $value;
    }

    private static function coords(array $input, array $defaults): array
    {
        $coords = [];
        foreach (['x', 'y', 'w', 'h'] as $key) {
            $raw = $input[$key] ?? $defaults[$key];
            $value = \filter_var($raw, FILTER_VALIDATE_INT);
            if ($value === false) {
                throw new ApiException('Координаты и размеры должны быть целыми числами.');
            }
            $coords[$key] = $value;
        }
        if ($coords['x'] < 0 || $coords['y'] < 0 || $coords['x'] > self::CANVAS_W || $coords['y'] > self::CANVAS_H) {
            throw new ApiException('Координаты выходят за пределы схемы (' . self::CANVAS_W . '×' . self::CANVAS_H . ').');
        }
        if ($coords['w'] < 20 || $coords['h'] < 20 || $coords['w'] > self::CANVAS_W || $coords['h'] > self::CANVAS_H) {
            throw new ApiException('Размер помещения: от 20 до ' . self::CANVAS_W . ' по ширине и до ' . self::CANVAS_H . ' по высоте.');
        }
        return $coords;
    }
}
