<?php
declare(strict_types=1);

namespace Ktits\Controllers;

use Ktits\Core\Auth;
use Ktits\Core\Database;
use Ktits\Core\Http;
use Ktits\Core\Validator;
use PDO;

final class UsersController
{
    private function pdo(): PDO
    {
        return Database::pdo();
    }

    private function requireAdmin(): array
    {
        $user = Auth::require();
        if ($user['role'] !== 'admin') {
            Http::error('Управлять пользователями может только администратор.', 403);
        }
        return $user;
    }

    public function get(): void
    {
        $this->requireAdmin();
        $rows = $this->pdo()->query('SELECT id, full_name, login, role, is_active, last_login_at, created_at FROM users ORDER BY id')->fetchAll();
        Http::json(['ok' => true, 'users' => \array_map(static fn ($row) => [
            'id' => (int)$row['id'], 'full_name' => $row['full_name'], 'login' => $row['login'],
            'role' => $row['role'], 'is_active' => (bool)$row['is_active'],
            'last_login_at' => $row['last_login_at'], 'created_at' => $row['created_at'],
        ], $rows)]);
    }

    public function create(): void
    {
        $this->requireAdmin();
        Auth::requireCsrf();
        $input = Http::input();
        $name = Validator::requireString($input, 'full_name', 150);
        $login = Validator::requireString($input, 'login', 50);
        if (!\preg_match('/^[A-Za-z0-9_.-]{3,50}$/', $login)) {
            Http::error('Логин: 3–50 латинских букв, цифр, точек, дефисов или подчёркиваний.');
        }
        $role = (string)($input['role'] ?? '');
        if (!\in_array($role, ['admin', 'schedule', 'content'], true)) {
            Http::error('Некорректная роль пользователя.');
        }
        $password = (string)($input['password'] ?? '');
        $generated = false;
        if ($password === '') {
            $password = \bin2hex(\random_bytes(5));
            $generated = true;
        }
        if (\strlen($password) < 8) {
            Http::error('Пароль должен содержать не менее 8 символов.');
        }
        $check = $this->pdo()->prepare('SELECT id FROM users WHERE login = ?');
        $check->execute([$login]);
        if ($check->fetch()) {
            Http::error('Пользователь с таким логином уже существует.', 409);
        }
        $stmt = $this->pdo()->prepare('INSERT INTO users (full_name, login, password_hash, role) VALUES (?, ?, ?, ?)');
        $stmt->execute([$name, $login, \password_hash($password, PASSWORD_DEFAULT), $role]);
        $id = (int)$this->pdo()->lastInsertId();
        Auth::log('create', 'users', $id, ['role' => $role]);
        Http::json([
            'ok' => true, 'id' => $id, 'generated_password' => $generated ? $password : null,
            'message' => 'Пользователь создан.',
        ], 201);
    }

    public function delete(int $id): void
    {
        $current = $this->requireAdmin();
        Auth::requireCsrf();
        if ($current['id'] === $id) {
            Http::error('Нельзя удалить собственную учётную запись.');
        }
        $stmt = $this->pdo()->prepare('SELECT role FROM users WHERE id = ?');
        $stmt->execute([$id]);
        $target = $stmt->fetch();
        if (!$target) {
            Http::error('Пользователь не найден.', 404);
        }
        if ($target['role'] === 'admin' && (int)$this->pdo()->query("SELECT COUNT(*) FROM users WHERE role = 'admin' AND is_active = 1")->fetchColumn() <= 1) {
            Http::error('Нельзя удалить последнего активного администратора.');
        }
        $this->pdo()->prepare('DELETE FROM users WHERE id = ?')->execute([$id]);
        Auth::log('delete', 'users', $id);
        Http::json(['ok' => true, 'message' => 'Пользователь удалён.']);
    }
}
