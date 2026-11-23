<?php
declare(strict_types=1);

namespace Ktits\Core;

final class Validator
{
    public static function clean(mixed $value, int $maxLength = 500): string
    {
        $value = \trim((string)$value);
        if (\function_exists('mb_substr')) {
            return \mb_substr($value, 0, $maxLength, 'UTF-8');
        }
        return \substr($value, 0, $maxLength);
    }

    public static function requireString(array $input, string $key, int $maxLength = 500): string
    {
        $value = self::clean($input[$key] ?? '', $maxLength);
        if ($value === '') {
            throw new ApiException('Заполните обязательные поля.');
        }
        return $value;
    }

    public static function date(string $value): string
    {
        $date = \DateTime::createFromFormat('Y-m-d', $value);
        if (!$date || $date->format('Y-m-d') !== $value) {
            throw new ApiException('Некорректная дата. Ожидается формат ГГГГ-ММ-ДД.');
        }
        return $value;
    }

    public static function time(string $value): string
    {
        if (!\preg_match('/^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/', $value)) {
            throw new ApiException('Некорректное время.');
        }
        return \strlen($value) === 5 ? $value . ':00' : $value;
    }

    public static function id(mixed $value): int
    {
        $id = \filter_var($value, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
        if ($id === false) {
            throw new ApiException('Некорректный идентификатор записи.');
        }
        return (int)$id;
    }
}
