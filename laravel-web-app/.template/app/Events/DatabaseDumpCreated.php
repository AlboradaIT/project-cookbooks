<?php

namespace App\Events;

use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;
use Carbon\Carbon;

class DatabaseDumpCreated
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public string $filePath,
        public string $relativePath,
        public string $filename,
        public string $database,
        public int $fileSize,
        public Carbon $createdAt
    ) {}
}
