<?php
declare(strict_types=1);

namespace Ktits\Core;

final class Http
{
    public static function method(): string
    {
        return \strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
    }

    public static function input(): array
    {
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
        if (\stripos($contentType, 'application/json') !== false) {
            $data = \json_decode((string)\file_get_contents('php://input'), true);
            if (!\is_array($data)) {
                self::error('Некорректный JSON в теле запроса.');
            }
            return $data;
        }
        return $_POST;
    }

    public static function json(mixed $data, int $status = 200): never
    {
        \http_response_code($status);
        \header('Content-Type: application/json; charset=utf-8');
        \header('Cache-Control: no-store');
        \header('X-Content-Type-Options: nosniff');
        \header('X-Frame-Options: DENY');
        \header("Content-Security-Policy: default-src 'none'; frame-ancestors 'none'");
        echo \json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    public static function error(string $message, int $status = 400, array $extra = []): never
    {
        self::json(\array_merge(['ok' => false, 'error' => $message], $extra), $status);
    }
}
