<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    fwrite(STDERR, "Скрипт предназначен только для запуска из командной строки.\n");
    exit(1);
}

if (!extension_loaded('curl')) {
    fwrite(STDERR, "FAIL Для smoke-теста нужно расширение PHP curl.\n");
    exit(1);
}

$baseUrl = rtrim(getenv('KTITS_BASE_URL') ?: 'http://ktits-info', '/');
$adminLogin = getenv('KTITS_ADMIN_LOGIN') ?: 'admin';
$adminPassword = getenv('KTITS_ADMIN_PASSWORD') ?: 'admin123';

/** Выполняет запрос к API и возвращает статус, JSON и cookies ответа. */
function apiRequest(
    string $baseUrl,
    string $method,
    string $action,
    array $query = [],
    ?array $body = null,
    string $cookie = ''
): array {
    $url = $baseUrl . '/api/index.php?' . http_build_query(
        array_merge(['action' => $action], $query),
        '',
        '&',
        PHP_QUERY_RFC3986
    );
    $headers = ['Accept: application/json'];
    if ($cookie !== '') {
        $headers[] = 'Cookie: ' . $cookie;
    }

    $options = [
        CURLOPT_URL => $url,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HEADER => true,
        CURLOPT_CONNECTTIMEOUT => 5,
        CURLOPT_TIMEOUT => 15,
        CURLOPT_HTTPHEADER => $headers,
    ];
    if ($body !== null) {
        $json = json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        if ($json === false) {
            throw new RuntimeException('Не удалось подготовить JSON запроса.');
        }
        $options[CURLOPT_POSTFIELDS] = $json;
        $options[CURLOPT_HTTPHEADER][] = 'Content-Type: application/json';
    }

    $curl = curl_init();
    curl_setopt_array($curl, $options);
    $response = curl_exec($curl);
    $error = curl_error($curl);
    $status = (int)curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
    $headerSize = (int)curl_getinfo($curl, CURLINFO_HEADER_SIZE);
    curl_close($curl);

    if (!is_string($response)) {
        return ['status' => 0, 'json' => null, 'cookies' => [], 'error' => $error];
    }

    $rawHeaders = substr($response, 0, $headerSize);
    $rawBody = substr($response, $headerSize);
    $data = json_decode($rawBody, true);
    $cookies = [];
    if (preg_match_all('/^Set-Cookie:\s*([^=;\r\n]+)=([^;\r\n]*)/mi', $rawHeaders, $matches, PREG_SET_ORDER)) {
        foreach ($matches as $match) {
            $cookies[$match[1]] = $match[1] . '=' . $match[2];
        }
    }

    return ['status' => $status, 'json' => $data, 'cookies' => $cookies, 'error' => $error];
}

/** Короткое пояснение для неудачной проверки без вывода паролей и cookies. */
function responseError(?array $response): string
{
    if ($response === null) {
        return 'запрос не выполнен: не получены данные групп';
    }
    if ($response['error'] !== '') {
        return $response['error'];
    }
    $message = 'получен HTTP ' . $response['status'];
    if (is_array($response['json']) && isset($response['json']['error'])) {
        $message .= ': ' . $response['json']['error'];
    } elseif (!is_array($response['json'])) {
        $message .= ': ответ не является JSON-объектом';
    }
    return $message;
}

$passed = 0;
$failed = 0;
$report = static function (string $name, bool $success, string $details = '') use (&$passed, &$failed): void {
    if ($success) {
        ++$passed;
        echo 'PASS ' . $name . PHP_EOL;
        return;
    }
    ++$failed;
    echo 'FAIL ' . $name . ($details !== '' ? ' — ' . $details : '') . PHP_EOL;
};

echo 'Smoke-тест API: ' . $baseUrl . PHP_EOL;

$bootstrap = apiRequest($baseUrl, 'GET', 'bootstrap');
$report(
    'GET bootstrap → 200 и ok:true',
    $bootstrap['status'] === 200 && ($bootstrap['json']['ok'] ?? null) === true,
    responseError($bootstrap)
);

$badLogin = apiRequest($baseUrl, 'POST', 'login', [], [
    'login' => $adminLogin,
    'password' => 'smoke-definitely-wrong-password',
]);
$report('POST login с неверным паролем → 401', $badLogin['status'] === 401, responseError($badLogin));

$login = apiRequest($baseUrl, 'POST', 'login', [], [
    'login' => $adminLogin,
    'password' => $adminPassword,
]);
$csrfToken = is_array($login['json']) ? ($login['json']['csrf_token'] ?? null) : null;
$report(
    'POST login администратора → 200, ok:true и csrf_token',
    $login['status'] === 200
        && ($login['json']['ok'] ?? null) === true
        && is_string($csrfToken)
        && $csrfToken !== '',
    responseError($login)
);
$sessionCookie = implode('; ', $login['cookies']);

$guestMap = apiRequest($baseUrl, 'GET', 'admin/map');
$report('GET admin/map без сессии → 401', $guestMap['status'] === 401, responseError($guestMap));

$map = apiRequest($baseUrl, 'GET', 'admin/map', [], null, $sessionCookie);
$report(
    'GET admin/map с сессией → 200 и список floors',
    $map['status'] === 200
        && ($map['json']['ok'] ?? null) === true
        && isset($map['json']['floors'])
        && is_array($map['json']['floors'])
        && $map['json']['floors'] !== [],
    responseError($map)
);

$groups = apiRequest($baseUrl, 'GET', 'admin/groups', [], null, $sessionCookie);
$groupList = is_array($groups['json']) && isset($groups['json']['groups']) && is_array($groups['json']['groups'])
    ? $groups['json']['groups']
    : [];
$report(
    'GET admin/groups с сессией → 200 и непустой список groups',
    $groups['status'] === 200 && ($groups['json']['ok'] ?? null) === true && $groupList !== [],
    responseError($groups)
);

$group = $groupList[0] ?? null;
$groupId = is_array($group) ? ($group['id'] ?? null) : null;
$schedule = is_int($groupId) && $groupId > 0
    ? apiRequest($baseUrl, 'GET', 'admin/schedule', ['group_id' => $groupId, 'day' => 1], null, $sessionCookie)
    : null;
$version = $schedule !== null && is_array($schedule['json']) ? ($schedule['json']['version'] ?? null) : null;
$report(
    'GET admin/schedule для существующей группы и дня → 200 и version',
    $schedule !== null
        && $schedule['status'] === 200
        && ($schedule['json']['ok'] ?? null) === true
        && is_string($version)
        && $version !== '',
    responseError($schedule)
);

$unknown = apiRequest($baseUrl, 'GET', 'smoke-unknown-action');
$report('Неизвестный action → 404', $unknown['status'] === 404, responseError($unknown));

$wrongMethod = apiRequest($baseUrl, 'POST', 'bootstrap');
$report('POST bootstrap → 405', $wrongMethod['status'] === 405, responseError($wrongMethod));

echo PHP_EOL . 'Итого: PASS=' . $passed . ', FAIL=' . $failed . PHP_EOL;
exit($failed > 0 ? 1 : 0);
