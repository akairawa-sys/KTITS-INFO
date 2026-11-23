<?php
declare(strict_types=1);

/* Разовый сброс паролей пользователей админ-панели.
   CLI: php tools/reset_passwords.php
   Выводит каждый пароль ОДИН раз. */

if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit('CLI only');
}

require __DIR__ . '/../../api/Core/Config.php';

use Ktits\Core\Config;

function password12(): string
{
    $alphabet = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789';
    $password = '';
    for ($i = 0; $i < 12; $i += 1) {
        $password .= $alphabet[random_int(0, strlen($alphabet) - 1)];
    }
    return $password;
}

$db = Config::get('db');
$pdo = new PDO(
    sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4', $db['host'], $db['port'], $db['name']),
    $db['user'],
    $db['pass'],
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$stmt = $pdo->query('SELECT id, login, role FROM users ORDER BY id');
echo "ПАРОЛИ ВЫВОДЯТСЯ ОДИН РАЗ. Сохраните их сразу:\n\n";
foreach ($stmt->fetchAll() as $user) {
    $password = password12();
    $hash = password_hash($password, PASSWORD_DEFAULT);
    $pdo->prepare('UPDATE users SET password_hash = ? WHERE id = ?')->execute([$hash, $user['id']]);
    echo "Логин {$user['login']} ({$user['role']}), новый пароль: {$password}\n";
}
echo "\nГотово.\n";
