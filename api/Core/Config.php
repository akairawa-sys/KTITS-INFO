<?php
declare(strict_types=1);

namespace Ktits\Core;

final class Config
{
    private static ?array $data = null;

    private static function load(): void
    {
        if (self::$data !== null) {
            return;
        }
        self::$data = [
            'db' => [
                'host' => getenv('KTITS_DB_HOST') ?: '127.0.0.1',
                'port' => (int)(getenv('KTITS_DB_PORT') ?: 3306),
                'name' => getenv('KTITS_DB_NAME') ?: 'ktits_info',
                'user' => getenv('KTITS_DB_USER') ?: 'root',
                'pass' => getenv('KTITS_DB_PASS') ?: '',
                'charset' => 'utf8mb4',
            ],
            'session_name' => 'ktits_admin',
            'upload_dir' => \dirname(__DIR__, 2) . \DIRECTORY_SEPARATOR . 'uploads',
            'max_upload_size' => 5 * 1024 * 1024,
            'max_import_size' => 10 * 1024 * 1024,
        ];
    }

    public static function get(string $key): mixed
    {
        self::load();
        $value = self::$data;
        foreach (\explode('.', $key) as $part) {
            if (!\is_array($value) || !\array_key_exists($part, $value)) {
                throw new \InvalidArgumentException("Неизвестный параметр конфигурации: {$key}");
            }
            $value = $value[$part];
        }
        return $value;
    }
}
