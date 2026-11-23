<?php
declare(strict_types=1);

namespace Ktits\Core;

use PDO;

final class Auth
{
    private static bool $started = false;

    public static function startSession(): void
    {
        if (self::$started || \session_status() === PHP_SESSION_ACTIVE) {
            return;
        }
        \session_name(Config::get('session_name'));
        \session_set_cookie_params([
            'httponly' => true,
            'samesite' => 'Lax',
            'secure' => !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off',
            'path' => '/',
        ]);
        \session_start();
        self::$started = true;
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = \bin2hex(\random_bytes(32));
        }
    }

    public static function csrfToken(): string
    {
        return $_SESSION['csrf_token'] ?? '';
    }

    public static function requireCsrf(): void
    {
        $input = Http::input();
        $token = $_SERVER['HTTP_X_CSRF_TOKEN'] ?? ($input['csrf_token'] ?? '');
        if (!$token || !\hash_equals($_SESSION['csrf_token'] ?? '', (string)$token)) {
            Http::error('Сессия устарела. Обновите страницу и повторите действие.', 403);
        }
    }

    public static function user(): ?array
    {
        return $_SESSION['user'] ?? null;
    }

    public static function require(?string $area = null): array
    {
        $user = self::user();
        if (!$user || empty($user['is_active'])) {
            Http::error('Требуется вход в панель администратора.', 401);
        }
        if ($area !== null && $user['role'] !== 'admin' && $user['role'] !== $area) {
            Http::error('Недостаточно прав для этого раздела.', 403);
        }
        return $user;
    }

    public static function publicUser(array $user): array
    {
        return [
            'id' => (int)$user['id'],
            'full_name' => $user['full_name'],
            'login' => $user['login'],
            'role' => $user['role'],
            'is_active' => (bool)$user['is_active'],
        ];
    }

    public static function payload(array $user): array
    {
        return ['ok' => true, 'user' => self::publicUser($user), 'csrf_token' => self::csrfToken()];
    }

    public static function login(string $login, string $password): array
    {
        $ip = (string)($_SERVER['REMOTE_ADDR'] ?? 'unknown');
        LoginThrottle::assertAllowed($ip, $login);
        if (\strlen($password) < 4) {
            LoginThrottle::recordFailure($ip, $login);
            Http::error('Введите логин и пароль.');
        }
        $stmt = Database::pdo()->prepare('SELECT * FROM users WHERE login = ? LIMIT 1');
        $stmt->execute([$login]);
        $user = $stmt->fetch();
        if (!$user || !$user['is_active'] || !\password_verify($password, $user['password_hash'])) {
            LoginThrottle::recordFailure($ip, $login);
            Http::error('Неверный логин или пароль.', 401);
        }
        LoginThrottle::clear($ip, $login);
        \session_regenerate_id(true);
        $_SESSION['user'] = self::publicUser($user);
        $_SESSION['csrf_token'] = \bin2hex(\random_bytes(32));
        Database::pdo()->prepare('UPDATE users SET last_login_at = NOW() WHERE id = ?')->execute([$user['id']]);
        self::log('login', 'users', $user['id']);
        return $user;
    }

    public static function logout(): void
    {
        self::require();
        self::requireCsrf();
        self::log('logout', 'users', self::user()['id'] ?? '');
        $_SESSION = [];
        if (\ini_get('session.use_cookies')) {
            $params = \session_get_cookie_params();
            \setcookie(\session_name(), '', \time() - 42000, $params['path'], $params['domain'] ?? '', $params['secure'], $params['httponly']);
        }
        \session_destroy();
    }

    public static function log(string $action, string $entity = '', mixed $entityId = '', array $details = []): void
    {
        $stmt = Database::pdo()->prepare('INSERT INTO activity_log (user_id, action, entity, entity_id, details) VALUES (?, ?, ?, ?, ?)');
        $stmt->execute([
            self::user()['id'] ?? null,
            $action,
            $entity,
            (string)$entityId,
            $details ? \json_encode($details, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) : null,
        ]);
    }
}
