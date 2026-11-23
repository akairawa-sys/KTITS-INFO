<?php
declare(strict_types=1);

namespace Ktits\Controllers;

use Ktits\Core\Auth;
use Ktits\Core\Http;
use Ktits\Core\Validator;

final class AuthController
{
    public function login(): void
    {
        $input = Http::input();
        $login = Validator::requireString($input, 'login', 50);
        $password = (string)($input['password'] ?? '');
        $user = Auth::login($login, $password);
        if (!empty($input['remember'])) {
            \setcookie(\session_name(), \session_id(), [
                'expires' => \time() + 30 * 86400,
                'path' => '/',
                'httponly' => true,
                'samesite' => 'Lax',
                'secure' => !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off',
            ]);
        }
        Http::json(Auth::payload($user));
    }

    public function logout(): void
    {
        Auth::logout();
        Http::json(['ok' => true]);
    }

    public function me(): void
    {
        Http::json(Auth::payload(Auth::require()));
    }
}
