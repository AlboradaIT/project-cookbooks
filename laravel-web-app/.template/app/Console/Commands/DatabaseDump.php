<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Event;
use Carbon\Carbon;

class DatabaseDump extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'db:dump {--path= : Custom path for the dump file}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Create a database dump with automatic naming and event emission';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Creating database dump...');

        // Generate filename with timestamp
        $timestamp = Carbon::now()->format('Y-m-d_H-i-s');
        $database = config('database.connections.mysql.database');
        $filename = "{$database}_{$timestamp}.sql";
        
        // Use custom path or default storage path
        $customPath = $this->option('path');
        $relativePath = $customPath ? rtrim($customPath, '/') . '/' . $filename : 'dumps/' . $filename;
        $fullPath = storage_path('app/' . $relativePath);
        
        // Ensure directory exists
        $directory = dirname($fullPath);
        if (!is_dir($directory)) {
            mkdir($directory, 0755, true);
        }

        // Database connection details
        $host = config('database.connections.mysql.host');
        $port = config('database.connections.mysql.port');
        $username = config('database.connections.mysql.username');
        $password = config('database.connections.mysql.password');

        // Build mysqldump command
        $command = sprintf(
            'mysqldump -h%s -P%s -u%s -p%s %s > %s',
            escapeshellarg($host),
            escapeshellarg($port),
            escapeshellarg($username),
            escapeshellarg($password),
            escapeshellarg($database),
            escapeshellarg($fullPath)
        );

        // Execute the command
        $output = [];
        $returnCode = 0;
        exec($command, $output, $returnCode);

        if ($returnCode === 0) {
            $fileSize = $this->formatBytes(filesize($fullPath));
            $this->info("Database dump created successfully!");
            $this->info("File: {$relativePath}");
            $this->info("Size: {$fileSize}");

            // Emit event for potential listeners (e.g., cloud storage upload)
            Event::dispatch('database.dump.created', [
                'file_path' => $fullPath,
                'relative_path' => $relativePath,
                'filename' => $filename,
                'database' => $database,
                'file_size' => filesize($fullPath),
                'created_at' => Carbon::now()
            ]);

            return Command::SUCCESS;
        } else {
            $this->error('Failed to create database dump.');
            return Command::FAILURE;
        }
    }

    /**
     * Format bytes to human-readable format
     */
    private function formatBytes($bytes, $precision = 2)
    {
        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        
        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, $precision) . ' ' . $units[$i];
    }
}
