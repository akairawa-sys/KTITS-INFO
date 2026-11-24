<?php
declare(strict_types=1);

namespace Ktits\Controllers;

use Ktits\Core\Database;
use PDO;

final class PublicController
{
    public function bootstrap(): array
    {
        $pdo = Database::pdo();
        $data = [];

        $bells = $pdo->query('SELECT * FROM bell_schedules WHERE is_active = 1 ORDER BY day_type, pair_number')->fetchAll();
        $data['BELLS_WEEK'] = [];
        $data['BELLS_SAT'] = [];
        foreach ($bells as $bell) {
            $data[$bell['day_type'] === 'sat' ? 'BELLS_SAT' : 'BELLS_WEEK'][] = [
                'n' => (int)$bell['pair_number'],
                'start' => \substr($bell['start_time'], 0, 5),
                'end' => \substr($bell['end_time'], 0, 5),
                'br' => $bell['break_text'],
            ];
        }

        $staffRows = $pdo->query('SELECT * FROM staff WHERE is_active = 1 ORDER BY sort_order, id')->fetchAll();
        $staff = ['management' => [], 'departments' => [], 'teachers' => [], 'itcubeHead' => '', 'itcube' => []];
        foreach ($staffRows as $row) {
            $photo = $row['photo_path'];
            switch ($row['category']) {
                case 'teachers':
                    $staff['teachers'][] = ['n' => $row['full_name'], 'cat' => $row['qualification'], 'subj' => $row['position'], 'photo' => $photo];
                    break;
                case 'management':
                    $staff['management'][] = ['name' => $row['full_name'], 'role' => $row['position'], 'room' => $row['room'], 'photo' => $photo];
                    break;
                case 'departments':
                    $staff['departments'][] = ['name' => $row['full_name'], 'head' => $row['department_head'], 'room' => $row['room'], 'spec' => $row['position'], 'photo' => $photo];
                    break;
                case 'itcube':
                    if ($row['is_head']) {
                        $staff['itcubeHead'] = $row['full_name'];
                        $staff['itcubeHeadPhoto'] = $photo;
                    } else {
                        $staff['itcube'][] = ['name' => $row['full_name'], 'subj' => $row['position'], 'photo' => $photo];
                    }
                    break;
            }
        }
        $data['STAFF'] = $staff;

        $newsRows = $pdo->query("SELECT * FROM news WHERE status = 'published' ORDER BY published_at DESC, id DESC")->fetchAll();
        $data['NEWS'] = \array_map(static function ($row) {
            return [
                'id' => (int)$row['id'],
                'tag' => $row['category'],
                'date' => \DateTime::createFromFormat('Y-m-d', $row['published_at'])->format('d.m.Y'),
                'title' => $row['title'],
                'text' => $row['summary'],
                'details' => $row['content'] ?? '',
                'image' => $row['image_path'],
            ];
        }, $newsRows);

        $months = [1 => 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
        $eventRows = $pdo->query("SELECT * FROM events WHERE status = 'published' AND event_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) ORDER BY event_date, event_time, id")->fetchAll();
        $data['EVENTS'] = \array_map(static function ($row) use ($months) {
            $date = new \DateTime($row['event_date']);
            return [
                'id' => (int)$row['id'],
                'title' => $row['title'],
                'description' => $row['description'] ?? '',
                'd' => $date->format('d'),
                'm' => $months[(int)$date->format('n')],
                'time' => $row['event_time'] ? \substr($row['event_time'], 0, 5) : '',
                'place' => $row['place'],
                'image' => $row['image_path'],
                'room_key' => $row['room_key'],
            ];
        }, $eventRows);

        $floors = $pdo->query('SELECT * FROM floors ORDER BY sort_order, id')->fetchAll();
        $roomStmt = $pdo->prepare('SELECT * FROM rooms WHERE floor_id = ? ORDER BY sort_order, id');
        $nodeStmt = $pdo->prepare('SELECT * FROM route_nodes WHERE floor_id = ? ORDER BY id');
        $edgeStmt = $pdo->prepare('SELECT e.node_a, e.node_b FROM route_edges e JOIN route_nodes n ON n.id = e.node_a WHERE n.floor_id = ? ORDER BY e.node_a, e.node_b');
        $data['FLOOR_PLANS'] = [];
        foreach ($floors as $floor) {
            $roomStmt->execute([$floor['id']]);
            $nodeStmt->execute([$floor['id']]);
            $edgeStmt->execute([$floor['id']]);
            $data['FLOOR_PLANS'][] = [
                'key' => $floor['floor_key'],
                'btn' => $floor['button_label'],
                'short' => $floor['short_title'],
                'title' => $floor['title'],
                'underlay_path' => $floor['underlay_path'],
                'underlay_opacity' => (float)$floor['underlay_opacity'],
                'underlay_scale' => (float)$floor['underlay_scale'],
                'rooms' => \array_map(static fn(array $room) => [
                    'id' => $room['room_key'], 'name' => $room['name'], 'type' => $room['type'],
                    'x' => (int)$room['x'], 'y' => (int)$room['y'], 'w' => (int)$room['w'], 'h' => (int)$room['h'],
                ], $roomStmt->fetchAll()),
                'route_nodes' => \array_map(static fn(array $node) => [
                    'id' => (int)$node['id'], 'floor_id' => (int)$node['floor_id'],
                    'x' => (int)$node['x'], 'y' => (int)$node['y'],
                    'kind' => $node['kind'], 'room_key' => $node['room_key'],
                ], $nodeStmt->fetchAll()),
                'route_edges' => \array_map(static fn(array $edge) => [
                    'node_a' => (int)$edge['node_a'], 'node_b' => (int)$edge['node_b'],
                ], $edgeStmt->fetchAll()),
            ];
        }

        $groups = $pdo->query('SELECT * FROM `groups` ORDER BY course, code')->fetchAll();
        $groupMap = [];
        $data['SCHEDULE_FULL'] = ['groups' => [], 'lessons' => []];
        foreach ($groups as $group) {
            $groupMap[(int)$group['id']] = $group['code'];
            $data['SCHEDULE_FULL']['groups'][] = ['id' => (int)$group['id'], 'code' => $group['code'], 'course' => (int)$group['course'], 'curator' => $group['curator']];
        }
        $lessons = $pdo->query('SELECT * FROM lessons ORDER BY group_id, day_of_week, pair_number')->fetchAll();
        foreach ($lessons as $lesson) {
            $data['SCHEDULE_FULL']['lessons'][] = [
                'id' => (int)$lesson['id'],
                'g' => $groupMap[(int)$lesson['group_id']],
                'day' => (int)$lesson['day_of_week'] - 1,
                'pair' => (int)$lesson['pair_number'],
                'room' => $lesson['room'],
                'subj' => $lesson['subject'],
                'teacher' => $lesson['teacher'],
                'cancelled' => (bool)$lesson['is_cancelled'],
            ];
        }

        $practiceRows = $pdo->query(
            'SELECT b.*, g.code AS group_code, g.course FROM practice_blocks b '
            . 'JOIN `groups` g ON g.id = b.group_id WHERE b.is_active = 1 ORDER BY b.sort_order, b.id'
        )->fetchAll();
        $practiceLessonRows = $pdo->query(
            'SELECT l.block_id, l.lesson_date, l.pair_number, l.room FROM practice_lessons l '
            . 'JOIN practice_blocks b ON b.id = l.block_id WHERE b.is_active = 1 '
            . 'ORDER BY l.block_id, l.lesson_date, l.pair_number, l.id'
        )->fetchAll();
        $practiceLessons = [];
        foreach ($practiceLessonRows as $lesson) {
            $practiceLessons[(int)$lesson['block_id']][] = [
                'date' => $lesson['lesson_date'],
                'pair' => (int)$lesson['pair_number'],
                'room' => $lesson['room'],
            ];
        }
        $data['PRACTICE'] = [];
        foreach ($practiceRows as $row) {
            $data['PRACTICE'][] = [
                'id' => (int)$row['id'],
                'group' => $row['group_code'],
                'course' => (int)$row['course'],
                'module' => $row['module'],
                'specialty' => $row['specialty'],
                'subgroup' => $row['subgroup'],
                'teacher' => $row['teacher'],
                'date_start' => $row['date_start'],
                'date_end' => $row['date_end'],
                'lessons' => $practiceLessons[(int)$row['id']] ?? [],
            ];
        }

        $itcubeRows = $pdo->query('SELECT day_of_week, start_time, end_time, room, subject, teacher, group_name FROM itcube_lessons ORDER BY day_of_week, start_time, sort_order')->fetchAll();
        $data['ITCUBE'] = \array_map(static fn ($row) => [
            'd' => (int)$row['day_of_week'] - 1,
            's' => \substr($row['start_time'], 0, 5),
            'e' => \substr($row['end_time'], 0, 5),
            'r' => $row['room'],
            'subj' => $row['subject'],
            't' => $row['teacher'],
            'g' => $row['group_name'],
        ], $itcubeRows);

        $settings = $pdo->query('SELECT setting_key, setting_value FROM settings')->fetchAll();
        $data['META'] = [];
        foreach ($settings as $setting) {
            $data['META'][$setting['setting_key']] = $setting['setting_value'];
        }
        $data['ok'] = true;
        return $data;
    }
}
