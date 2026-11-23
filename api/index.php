<?php
declare(strict_types=1);

spl_autoload_register(static function (string $class): void {
    $prefix = 'Ktits\\';
    if (!str_starts_with($class, $prefix)) {
        return;
    }
    $relative = str_replace('\\', '/', substr($class, strlen($prefix)));
    $file = __DIR__ . '/' . $relative . '.php';
    if (is_file($file)) {
        require_once $file;
    }
});

use Ktits\Controllers\AuthController;
use Ktits\Controllers\BellsController;
use Ktits\Controllers\MapController;
use Ktits\Controllers\PostsController;
use Ktits\Controllers\PracticeController;
use Ktits\Controllers\PublicController;
use Ktits\Controllers\ScheduleController;
use Ktits\Controllers\StaffController;
use Ktits\Controllers\UploadController;
use Ktits\Controllers\UsersController;
use Ktits\Core\ApiException;
use Ktits\Core\Auth;
use Ktits\Core\Http;
use Ktits\Core\Validator;

Auth::startSession();

$routes = [
    'GET bootstrap' => [PublicController::class, 'bootstrap'],
    'POST login' => [AuthController::class, 'login'],
    'POST logout' => [AuthController::class, 'logout'],
    'GET me' => [AuthController::class, 'me'],

    'GET admin/groups' => [ScheduleController::class, 'groups'],
    'GET admin/schedule' => [ScheduleController::class, 'get'],
    'PUT admin/schedule' => [ScheduleController::class, 'save'],
    'POST admin/schedule/import' => [ScheduleController::class, 'import'],
    'GET admin/schedule/template' => [ScheduleController::class, 'template'],

    'GET admin/practice' => [PracticeController::class, 'get'],
    'POST admin/practice' => [PracticeController::class, 'create'],
    'PUT admin/practice/item' => [PracticeController::class, 'save', ['id']],
    'DELETE admin/practice/item' => [PracticeController::class, 'delete', ['id']],

    'GET admin/bells' => [BellsController::class, 'get'],
    'PUT admin/bells' => [BellsController::class, 'save'],
    'PUT admin/bells/time' => [BellsController::class, 'updateTime'],

    'GET admin/staff' => [StaffController::class, 'get'],
    'POST admin/staff' => [StaffController::class, 'save'],
    'PUT admin/staff/item' => [StaffController::class, 'save', ['id']],
    'DELETE admin/staff/item' => [StaffController::class, 'delete', ['id']],

    'GET admin/news' => [PostsController::class, 'get', ['news']],
    'POST admin/news' => [PostsController::class, 'save', ['news']],
    'PUT admin/news/item' => [PostsController::class, 'save', ['news', 'id']],
    'DELETE admin/news/item' => [PostsController::class, 'delete', ['news', 'id']],

    'GET admin/events' => [PostsController::class, 'get', ['events']],
    'POST admin/events' => [PostsController::class, 'save', ['events']],
    'PUT admin/events/item' => [PostsController::class, 'save', ['events', 'id']],
    'DELETE admin/events/item' => [PostsController::class, 'delete', ['events', 'id']],

    'GET admin/users' => [UsersController::class, 'get'],
    'POST admin/users' => [UsersController::class, 'create'],
    'DELETE admin/users/item' => [UsersController::class, 'delete', ['id']],

    'POST admin/upload' => [UploadController::class, 'store'],

    'GET admin/map' => [MapController::class, 'get'],
    'POST admin/map' => [MapController::class, 'create'],
    'PUT admin/map/item' => [MapController::class, 'save', ['id']],
    'DELETE admin/map/item' => [MapController::class, 'delete', ['id']],
    'POST admin/map/convert' => [MapController::class, 'convert'],
    'PUT admin/map/floor' => [MapController::class, 'saveFloor'],
    'POST admin/map/node' => [MapController::class, 'createNode'],
    'PUT admin/map/node' => [MapController::class, 'saveNode', ['id']],
    'DELETE admin/map/node' => [MapController::class, 'deleteNode', ['id']],
    'POST admin/map/edge' => [MapController::class, 'createEdge'],
    'DELETE admin/map/edge' => [MapController::class, 'deleteEdge'],
];

$action = (string)($_GET['action'] ?? 'bootstrap');
$method = Http::method();

$actions = [];
foreach (array_keys($routes) as $routeKey) {
    [$routeMethod, $routeAction] = explode(' ', $routeKey, 2);
    $actions[$routeAction][] = $routeMethod;
}

try {
    if (!isset($actions[$action])) {
        Http::error('Запрошенный действие API не найдено.', 404);
    }
    if (!isset($routes["$method $action"])) {
        Http::error('Метод не поддерживается для этого действия.', 405);
    }
    [$controllerClass, $handler, $args] = $routes["$method $action"] + [2 => []];
    $args = array_map(
        static fn(string $arg) => $arg === 'id' ? Validator::id($_GET['id'] ?? 0) : $arg,
        $args
    );
    $controller = new $controllerClass();
    $result = $controller->{$handler}(...$args);
    if (is_array($result)) {
        Http::json($result);
    }
} catch (ApiException $e) {
    Http::error($e->getMessage(), $e->status, $e->extra);
} catch (InvalidArgumentException $e) {
    Http::error($e->getMessage(), 422);
} catch (Throwable $e) {
    error_log('[KTITS-INFO] ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine());
    Http::error('Внутренняя ошибка сервера. Проверьте подключение к MySQL и журнал PHP.', 500);
}
