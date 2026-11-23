<?php
declare(strict_types=1);

namespace Ktits\Core;

final class LoginThrottle
{
    private const MAX_ATTEMPTS = 5;
    private const WINDOW_SECONDS = 600;

    public static function assertAllowed(string $ip, string $login): void
    {
        self::update(static function (array &$attempts, int $now) use ($ip, $login): void {
            $key = self::key($ip, $login);
            if (\count($attempts[$key] ?? []) >= self::MAX_ATTEMPTS) {
                throw new ApiException('Слишком много попыток, повторите позже', 429);
            }
        });
    }

    public static function recordFailure(string $ip, string $login): void
    {
        self::update(static function (array &$attempts, int $now) use ($ip, $login): void {
            $key = self::key($ip, $login);
            $attempts[$key][] = $now;
        });
    }

    public static function clear(string $ip, string $login): void
    {
        self::update(static function (array &$attempts, int $now) use ($ip, $login): void {
            unset($attempts[self::key($ip, $login)]);
        });
    }

    private static function update(callable $callback): void
    {
        $directory = \dirname(__DIR__) . \DIRECTORY_SEPARATOR . 'storage';
        if (!\is_dir($directory) && !\mkdir($directory, 0775, true) && !\is_dir($directory)) {
            throw new \RuntimeException('Не удалось создать каталог счётчика входов.');
        }

        $file = $directory . \DIRECTORY_SEPARATOR . 'login_attempts.json';
        $handle = \fopen($file, 'c+b');
        if ($handle === false) {
            throw new \RuntimeException('Не удалось открыть файл счётчика входов.');
        }

        try {
            if (!\flock($handle, LOCK_EX)) {
                throw new \RuntimeException('Не удалось заблокировать файл счётчика входов.');
            }

            $contents = \stream_get_contents($handle);
            $attempts = \is_string($contents) && $contents !== '' ? \json_decode($contents, true) : [];
            if (!\is_array($attempts)) {
                $attempts = [];
            }

            $now = \time();
            $cutoff = $now - self::WINDOW_SECONDS;
            foreach ($attempts as $key => $timestamps) {
                if (!\is_array($timestamps)) {
                    unset($attempts[$key]);
                    continue;
                }
                $timestamps = \array_values(\array_filter(
                    $timestamps,
                    static fn ($timestamp): bool => \is_int($timestamp) && $timestamp > $cutoff
                ));
                if ($timestamps === []) {
                    unset($attempts[$key]);
                } else {
                    $attempts[$key] = $timestamps;
                }
            }

            $callback($attempts, $now);
            $json = \json_encode($attempts, JSON_UNESCAPED_SLASHES);
            if ($json === false) {
                throw new \RuntimeException('Не удалось закодировать счётчик входов.');
            }
            \rewind($handle);
            if (!\ftruncate($handle, 0) || \fwrite($handle, $json) === false) {
                throw new \RuntimeException('Не удалось записать счётчик входов.');
            }
            \fflush($handle);
        } finally {
            \flock($handle, LOCK_UN);
            \fclose($handle);
        }
    }

    private static function key(string $ip, string $login): string
    {
        return \hash('sha256', $ip . "\0" . $login);
    }
}
