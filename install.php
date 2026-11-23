<?php
declare(strict_types=1);

use Ktits\Core\Config;

if (PHP_SAPI !== 'cli') {
    http_response_code(403);
    exit('Скрипт предназначен только для запуска из командной строки.');
}

require __DIR__ . '/api/Core/Config.php';

function generatePassword(int $length = 12): string
{
    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    $lastIndex = strlen($alphabet) - 1;
    $password = '';

    for ($i = 0; $i < $length; $i++) {
        $password .= $alphabet[random_int(0, $lastIndex)];
    }

    return $password;
}

try {
    $host = Config::get('db.host');
    $port = Config::get('db.port');
    $dbName = Config::get('db.name');
    $charset = Config::get('db.charset');

    $pdo = new PDO(
        "mysql:host={$host};port={$port};charset={$charset}",
        Config::get('db.user'),
        Config::get('db.pass'),
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );

    $quotedDbName = '`' . str_replace('`', '``', $dbName) . '`';
    $pdo->exec("CREATE DATABASE IF NOT EXISTS {$quotedDbName} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    $pdo->exec("USE {$quotedDbName}");

    $tableQuery = $pdo->prepare(
        'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = ? AND table_name = ?'
    );
    $tableQuery->execute([$dbName, 'users']);
    $usersTableExists = (int)$tableQuery->fetchColumn() > 0;

    if ($usersTableExists) {
        echo "Таблица users уже существует: импорт дампа пропущен, данные сохранены." . PHP_EOL;
    } else {
        $tablesQuery = $pdo->prepare('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = ?');
        $tablesQuery->execute([$dbName]);
        if ((int)$tablesQuery->fetchColumn() > 0) {
            throw new RuntimeException(
                'База не пуста, но таблица users отсутствует. Автоматический импорт отменён.'
            );
        }

        $dumpPath = __DIR__ . '/KTITS-INFO.sql';
        $sql = file_get_contents($dumpPath);
        if ($sql === false) {
            throw new RuntimeException("Не удалось прочитать файл {$dumpPath}.");
        }

        $sql = preg_replace(
            '/CREATE DATABASE IF NOT EXISTS `[^`]+`\s+DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\s+USE `[^`]+`;/',
            '',
            $sql,
            1
        );
        if ($sql === null || trim($sql) === '') {
            throw new RuntimeException('Дамп пуст или имеет неподдерживаемый формат.');
        }

        $pdo->exec($sql);
        echo "Схема и данные из KTITS-INFO.sql импортированы." . PHP_EOL;
    }

    $users = [
        ['login' => 'admin', 'full_name' => 'Администратор системы', 'role' => 'admin'],
        ['login' => 'schedule', 'full_name' => 'Редактор расписания', 'role' => 'schedule'],
        ['login' => 'content', 'full_name' => 'Редактор контента', 'role' => 'content'],
    ];

    $select = $pdo->prepare('SELECT password_hash FROM users WHERE login = :login');
    $insert = $pdo->prepare(
        'INSERT INTO users (full_name, login, password_hash, role) VALUES (:full_name, :login, :password_hash, :role)'
    );
    $update = $pdo->prepare(
        "UPDATE users SET password_hash = :password_hash WHERE login = :login AND password_hash = 'SET_ON_INSTALL'"
    );

    $credentials = [];

    foreach ($users as $user) {
        $select->execute(['login' => $user['login']]);
        $currentHash = $select->fetchColumn();

        if ($currentHash !== false && $currentHash !== 'SET_ON_INSTALL') {
            echo "Пользователь {$user['login']} уже существует: пароль не изменён." . PHP_EOL;
            continue;
        }

        $password = generatePassword();
        $passwordHash = password_hash($password, PASSWORD_DEFAULT);

        if ($currentHash === false) {
            $insert->execute([
                'full_name' => $user['full_name'],
                'login' => $user['login'],
                'password_hash' => $passwordHash,
                'role' => $user['role'],
            ]);
        } else {
            $update->execute([
                'password_hash' => $passwordHash,
                'login' => $user['login'],
            ]);
            if ($update->rowCount() !== 1) {
                echo "Пароль пользователя {$user['login']} был изменён параллельно и не перезаписан." . PHP_EOL;
                continue;
            }
        }

        $credentials[] = ['login' => $user['login'], 'password' => $password];
        echo "Пользователь {$user['login']} создан." . PHP_EOL;
    }

    if ($credentials === []) {
        echo "Новые пароли не создавались." . PHP_EOL;
    } else {
        echo PHP_EOL . "НОВЫЕ ПАРОЛИ — сохраните их, повторно они не выводятся:" . PHP_EOL;
        foreach ($credentials as $credential) {
            echo "Логин {$credential['login']}, пароль: {$credential['password']}" . PHP_EOL;
        }
    }

    echo PHP_EOL . "Установка завершена." . PHP_EOL;
} catch (Throwable $e) {
    fwrite(STDERR, 'Ошибка установки: ' . $e->getMessage() . PHP_EOL);
    exit(1);
}
