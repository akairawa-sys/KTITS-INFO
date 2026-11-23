<?php
declare(strict_types=1);

namespace Ktits\Services;

use Ktits\Core\ApiException;
use ZipArchive;

final class SpreadsheetReader
{
    public static function read(string $tmpName, string $originalName): array
    {
        $extension = \strtolower(\pathinfo($originalName, PATHINFO_EXTENSION));
        if ($extension === 'csv') {
            return self::readCsv($tmpName);
        }
        if (\in_array($extension, ['xlsx', 'xls'], true)) {
            if ($extension === 'xls') {
                throw new ApiException('Старый формат .xls не поддерживается. Сохраните файл как .xlsx или .csv.');
            }
            return self::readXlsx($tmpName);
        }
        throw new ApiException('Поддерживаются файлы .xlsx и .csv.');
    }

    private static function readCsv(string $path): array
    {
        $content = \file_get_contents($path);
        if ($content === false) {
            throw new ApiException('Не удалось прочитать CSV-файл.');
        }
        $content = \preg_replace('/^\xEF\xBB\xBF/', '', $content);
        if (\function_exists('mb_check_encoding') && !\mb_check_encoding($content, 'UTF-8')) {
            $content = \mb_convert_encoding($content, 'UTF-8', 'Windows-1251');
        }
        $firstLine = \strtok($content, "\r\n") ?: '';
        $delimiter = \substr_count($firstLine, ';') >= \substr_count($firstLine, ',') ? ';' : ',';
        $stream = \fopen('php://temp', 'r+');
        \fwrite($stream, $content);
        \rewind($stream);
        $rows = [];
        while (($row = \fgetcsv($stream, 0, $delimiter)) !== false) {
            $rows[] = $row;
        }
        \fclose($stream);
        return $rows;
    }

    private static function readXlsx(string $path): array
    {
        if (!\class_exists(ZipArchive::class)) {
            throw new ApiException('Для XLSX включите расширение php_zip в OpenServer.', 500);
        }
        $zip = new ZipArchive();
        if ($zip->open($path) !== true) {
            throw new ApiException('Не удалось открыть XLSX-файл.');
        }
        $sheet = $zip->getFromName('xl/worksheets/sheet1.xml');
        $sharedXml = $zip->getFromName('xl/sharedStrings.xml');
        if ($sheet === false) {
            $zip->close();
            throw new ApiException('В XLSX-файле не найден первый лист.');
        }
        $shared = [];
        if ($sharedXml !== false) {
            $xml = \simplexml_load_string($sharedXml);
            foreach ($xml->si as $item) {
                $parts = $item->xpath('.//*[local-name()="t"]');
                $shared[] = \implode('', \array_map('strval', $parts));
            }
        }
        $xml = \simplexml_load_string($sheet);
        $rows = [];
        foreach ($xml->sheetData->row as $rowNode) {
            $row = [];
            foreach ($rowNode->c as $cell) {
                $reference = (string)$cell['r'];
                \preg_match('/^[A-Z]+/', $reference, $match);
                $letters = $match[0] ?? 'A';
                $index = 0;
                for ($i = 0, $len = \strlen($letters); $i < $len; $i++) {
                    $index = $index * 26 + \ord($letters[$i]) - 64;
                }
                $index--;
                $type = (string)$cell['t'];
                if ($type === 'inlineStr') {
                    $parts = $cell->xpath('.//*[local-name()="t"]');
                    $value = \implode('', \array_map('strval', $parts));
                } else {
                    $raw = (string)$cell->v;
                    $value = $type === 's' ? ($shared[(int)$raw] ?? '') : $raw;
                }
                $row[$index] = $value;
            }
            if ($row) {
                \ksort($row);
                $max = \max(\array_keys($row));
                $rows[] = \array_map(static fn ($i) => $row[$i] ?? '', \range(0, $max));
            } else {
                $rows[] = [];
            }
        }
        $zip->close();
        return $rows;
    }
}
