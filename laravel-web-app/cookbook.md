# Dockerized Laravel Application - AlboradaIT Cookbook

This cookbook provides a streamlined workflow for creating Laravel Docker projects using a template-based approach.

### Prerequisites

1. **Docker & Docker Compose** installed
2. **Git** configured
3. **GitHub CLI** (optional, for repository creation)

## Creating a New Laravel Project

### Agent Workflow

When a user requests a Laravel project:

1. **Ask for application name if not provided**
2. **Generate configuration table** with defaults:
   - Project: [User's input]
   - Directory: [kebab-case]
   - Database: [snake_case - NO _db suffix]
   - Domain: [kebab-case.local]
   - Password: [Generated]
3. **Ask for confirmation**: "Would you like to change anything?"
4. **Handle changes if needed**
5. **Execute create-project script** with all parameters via curl

**STREAMLINED:** Single curl command handles everything - no manual cloning or multiple confirmations needed!

### Example Interaction

```
Agent: "What's the application name?"
User: "Housing Management System"
Agent: 

| Parameter | Value |
|-----------|-------|
| Project | Housing Management System |
| Directory | housing-management-system |
| Database | housing_management_system |
| Domain | housing-management-system.local |
| Password | [Generated] |

"Would you like to change anything?: "
User: "no"
Agent: "Setting up your project..."
```

### Setup Script Execution

The agent should run the create-project script directly via curl:

```bash
curl -fsSL https://raw.githubusercontent.com/AlboradaIT/project-cookbooks/main/laravel-web-app/create-project.sh | bash -s -- "Housing Management System" "housing_management_system" "housing-management-system.local" "optional-password"
```

**STREAMLINED PROCESS:** 
- Single command execution - no multiple confirmations needed
- Script handles repository cloning internally  
- Laravel is pre-installed during project creation
- Containers start immediately with Laravel ready
- Sail commands available from the start

## Setup Script Details

The `create-project.sh` script handles:

1. **Repository cloning** - Clones cookbook repository to temporary location
2. **Parameter processing** - Accepts project name, database, domain, password
3. **Directory creation** - Creates kebab-case project directory
4. **Template copying** - Copies `.template` files safely
5. **Environment configuration** - Updates .env with provided values
6. **Laravel pre-installation** - Installs Laravel using project's container image
7. **Docker Compose setup** - Processes .stub files with placeholders
8. **Git initialization** - Creates new repository
9. **Cleanup** - Removes temporary files

### Script Usage

The agent should execute via curl with parameters:

```bash
curl -fsSL https://raw.githubusercontent.com/AlboradaIT/project-cookbooks/main/laravel-web-app/create-project.sh | bash -s -- <project-name> [db-name] [domain] [password]
```

**Parameters:**
- `project-name`: Application name (any format)
- `db-name`: Database name (defaults to snake_case of project name)
- `domain`: Application domain (defaults to kebab-case.local)
- `password`: Database password (defaults to generated secure password)

## Project Structure

Each generated project includes:

```
project-directory/
├── docker/
│   ├── database/mysql/     # MySQL configuration
│   ├── runtimes/8.2/       # PHP 8.2-FPM runtime
│   ├── webserver/nginx/    # Nginx configuration
│   └── reverse-proxy/      # Traefik labels
├── app/
│   ├── Console/Commands/   # Custom Laravel commands
│   │   └── DatabaseDump.php
│   └── Events/             # Laravel events
│       └── DatabaseDumpCreated.php
├── .env                    # Environment configuration
├── docker-compose.yml      # Docker services
└── README.md              # Project documentation
```

## Docker Services

Each project provides:

- **Laravel** (latest version with PHP 8.2-FPM)
- **Nginx** (Alpine, optimized configuration)
- **MySQL 8.0** (persistent data)
- **Traefik** (reverse proxy with automatic SSL)

## Development Workflow

### Starting a Project

```bash
cd ~/projects/project-directory
docker-compose up -d

# Laravel is already installed and ready!
# Access via https://your-domain.local
```

### Laravel Pre-Installation

Laravel is now pre-installed during project creation:
1. Laravel is installed using the project's container image during setup
2. Environment variables are configured automatically
3. Application key is generated during installation
4. Project is ready to start immediately

### Custom Laravel Commands

**Database Dump Command:**
```bash
# Basic dump
docker-compose exec app php artisan db:dump

# Dump specific tables
docker-compose exec app php artisan db:dump --tables=users,posts

# Custom filename
docker-compose exec app php artisan db:dump --filename=backup-2024-01-15
```

Dumps are saved to `storage/app/database-dumps/` and emit a `DatabaseDumpCreated` event.

### Common Commands

```bash
# View logs
docker-compose logs -f app

# Laravel artisan commands (sail is available immediately!)
./vendor/bin/sail artisan migrate
./vendor/bin/sail artisan make:controller UserController

# Or use docker-compose
docker-compose exec app php artisan migrate
docker-compose exec app php artisan make:controller UserController

# Access container shell
docker-compose exec app bash

# Database access
docker-compose exec mysql mysql -u [username] -p
```

## Troubleshooting

### HTTPS 404 Errors

If you get 404 errors when accessing https://your-domain.local:

1. **Check Traefik is running**:
   ```bash
   docker ps | grep traefik
   curl http://localhost:8080  # Traefik dashboard
   ```

2. **Restart both nginx and Traefik**:
   ```bash
   cd ~/projects/your-project
   docker-compose restart nginx
   cd docker/reverse-proxy/traefik && docker-compose restart traefik
   ```

3. **Verify service discovery**:
   ```bash
   curl -s http://localhost:8080/api/rawdata | jq '.http.routers'
   ```

### Database Session Errors

If you get "Table 'database.sessions' doesn't exist" errors:

```bash
# Run database migrations
./vendor/bin/sail artisan migrate
# Or using docker-compose
docker-compose exec app php artisan migrate
```

**Note**: Modern Laravel includes the sessions table in the main user migration.

### Port Conflicts

If MySQL port 3306 is in use:
```bash
# Edit docker-compose.yml to use different port
sed -i 's/3306:3306/3307:3306/' docker-compose.yml
docker-compose up -d
```

### Traefik Issues

```bash
# Recreate Traefik network
docker network create traefik
cd ~/shared-services/traefik && docker-compose up -d
```

### Permission Issues

```bash
# Fix Laravel storage permissions
docker-compose exec app chmod -R 775 storage bootstrap/cache
docker-compose exec app chown -R sail:sail storage bootstrap/cache
```

### Environment Issues

Laravel is pre-installed during project creation with proper environment configuration:
- Environment variables are set up automatically during project creation
- No .env backup/restore needed as Laravel is installed after .env configuration

## GitHub Repository Creation

### Automatic (via create-project script)

The create-project script can create repositories if GitHub CLI is configured:
```bash
gh auth login  # One-time setup
# After project creation, manually create repository if desired
```

### Manual

```bash
cd ~/projects/project-directory

# Create private repository
gh repo create AlboradaIT/project-name --private --source=. --push

# Or public repository
gh repo create AlboradaIT/project-name --public --source=. --push
```

## Best Practices

### Project Naming
- Use descriptive names with spaces: "Housing Management System"
- Script handles technical naming automatically

### Environment Management
- Environment variables are configured automatically during project creation
- Never commit .env files
- Use unique database passwords per project
- Keep credentials secure

### Docker Management
- Regular cleanup: `docker system prune`
- Monitor disk usage: `docker system df`

### Development
- Laravel is ready immediately after project creation
- Use sail commands for easier Laravel management: `./vendor/bin/sail artisan`
- Use migrations for database changes
- Regular backups with `db:dump` command
- Follow Laravel best practices

---

*This cookbook is maintained by the AlboradaIT development team. For updates, check the project-cookbooks repository.*
