<?php
declare(strict_types=1);

namespace Ktits\Controllers;

use finfo;
use Ktits\Core\Auth;
use Ktits\Core\Config;
use Ktits\Core\Http;

final class UploadController
{
    public function store(): void
    {
        Auth::require('content');
        Auth::requireCsrf();
        $file = $_FILES['file'] ?? null;
        if (!$file || !isset($file['tmp_name']) || $file['error'] !== UPLOAD_ERR_OK) {
            Http::error('Выберите изображение для загрузки.');
        }
        if ($file['size'] > (int)Config::get('max_upload_size')) {
            Http::error('Размер файла превышает 5 МБ.');
        }
        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime = $finfo->file($file['tmp_name']);
        $extensions = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'];
        if (!isset($extensions[$mime])) {
            Http::error('Поддерживаются только JPG, PNG и WEBP.');
        }
        $uploadDir = (string)Config::get('upload_dir');
        if (!\is_dir($uploadDir) && !\mkdir($uploadDir, 0775, true) && !\is_dir($uploadDir)) {
            Http::error('Не удалось создать папку uploads.', 500);
        }
        $filename = \date('Ymd') . '-' . \bin2hex(\random_bytes(8)) . '.' . $extensions[$mime];
        $target = $uploadDir . \DIRECTORY_SEPARATOR . $filename;
        if (!\move_uploaded_file($file['tmp_name'], $target)) {
            Http::error('Не удалось сохранить файл. Проверьте права на папку uploads.', 500);
        }
        Auth::log('upload', 'file', $filename);
        Http::json(['ok' => true, 'path' => 'uploads/' . $filename], 201);
    }
}
