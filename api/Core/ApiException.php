<?php
declare(strict_types=1);

namespace Ktits\Core;

final class ApiException extends \RuntimeException
{
    public function __construct(
        string $message,
        public readonly int $status = 400,
        public readonly array $extra = []
    ) {
        parent::__construct($message);
    }
}
