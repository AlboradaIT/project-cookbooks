# Copilot Instructions for Laravel Project

## Project Overview
This is a dockerized Laravel application developed for AlboradaIT. The project uses Docker with PHP-FPM, Nginx, MySQL, integrated with Traefik for reverse proxy.

## Development Environment
- **Container-based development**: Use `sail` commands for all operations
- **No local PHP required**: All PHP operations run inside containers
- **Traefik integration**: Project accessible via configured domain

## Code Style Guidelines

### HTML Formatting
Use vertical class and attributes formatting for readability:

```php
<div
    class="
        popper-box 
        rounded-md 
        border 
        border-slate-150
    "
    id="example-element"
    data-toggle="modal"
>
    Content here
</div>
```

### PHP Code Organization
- **Purpose first, then alphabetical**: Group functions by purpose (scopes, getters, relations, etc.)
- **Within groups**: Arrange functions alphabetically when adding new ones
- **Class structure**: Properties first, then constructor, then methods grouped by purpose

### Suggested Integrations
Use these packages only when specifically needed:
- **Stripe Payments**: Laravel Cashier
- **User Permissions**: Spatie Laravel Permission
- **File Management**: Spatie Laravel Media Library

## Development Commands

### Container Management
```bash
# Start all services
sail up -d

# Stop all services
sail down

# Rebuild containers
sail build --no-cache

# View logs
sail logs
```

### Laravel Commands
```bash
# Run migrations
sail artisan migrate

# Generate application key
sail artisan key:generate

# Create database dump
sail artisan db:dump

# Clear caches
sail artisan optimize:clear
```

### Database Operations
```bash
# Access MySQL CLI
sail mysql

# Run seeders
sail artisan db:seed

# Fresh migration with seeders
sail artisan migrate:fresh --seed
```

## Project Structure
```
project-root/
├── app/                       # Laravel application code
├── docker/                    # Docker configuration
│   ├── database/mysql/        # MySQL configuration
│   ├── runtimes/8.2/          # PHP-FPM configuration
│   └── webserver/nginx/       # Nginx configuration
├── .github/                   # GitHub workflows and copilot instructions
├── docker-compose.yml         # Container orchestration
└── .env                       # Environment configuration
```

## Important Notes
- Always use `sail` command instead of direct `php` or `artisan`
- Database dumps are automatically created with `sail artisan db:dump`
- All file operations should maintain proper permissions
- Follow AlboradaIT naming conventions (kebab-case for projects)

## Troubleshooting
- If containers fail to start, check `.env` configuration
- For permission issues, rebuild containers with correct WWWUSER/WWWGROUP
- For Traefik issues, ensure external network exists: `docker network create traefik`
