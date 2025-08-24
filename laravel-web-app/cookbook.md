# Dockerized Laravel Application - AlboradaIT Cookbook

This cookbook provides a streamlined workflow for creating Laravel Docker projects using a template-based approach.

### Prerequisites

1. **Docker & Docker Compose** installed
2. **Git** configured
3. **GitHub CLI** (optional, for repository creation)

## Creating a New Laravel Project

### Agent Workflow

When a user requests a Laravel project:

1. **Ask for application name** (spaces allowed)
2. **Generate configuration table** with defaults:
   - Project: [User's input]
   - Directory: [kebab-case]
   - Database: [snake_case - NO _db suffix]
   - Domain: [kebab-case.local]
   - Password: [Generated]
3. **Ask for confirmation**: "Would you like to change anything?"
4. **Handle changes if needed**
5. **Clone cookbook repository** to temporary location
6. **Execute setup script** with all parameters from temporary location
7. **Clean up** temporary cookbook files

**CRITICAL:** Never modify the user's existing cookbook repository. Always clone to /tmp/ first.

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

The agent should clone the cookbook repository to a temporary location and run the setup script:

```bash
# Clone cookbook repository to temporary location
git clone https://github.com/AlboradaIT/project-cookbooks.git /tmp/project-cookbooks

# Navigate to the Laravel template
cd /tmp/project-cookbooks/laravel-web-app

# Run setup script with parameters
./setup.sh "Housing Management System" "housing_management_system" "housing-management-system.local" "optional-password"

# Clean up temporary files
rm -rf /tmp/project-cookbooks
```

**Important:** Never run the setup script from the user's existing cookbooks directory. Always clone to a temporary location first.

## Setup Script Details

The `setup.sh` script handles:

1. **Parameter processing** - Accepts project name, database, domain, password
2. **Directory creation** - Creates kebab-case project directory
3. **Template copying** - Copies `.template` files safely
4. **Environment configuration** - Updates .env with provided values
5. **Docker Compose setup** - Processes .stub files with placeholders
6. **Git initialization** - Creates new repository
7. **Traefik verification** - Checks if reverse proxy is running

### Script Usage

```bash
./setup.sh <project-name> [db-name] [domain] [password]
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

# Wait for Laravel installation (first run only)
# Access via https://your-domain.local
```

### Laravel Auto-Installation

On first container start:
1. Laravel is automatically installed via Composer
2. Existing .env files are preserved and restored
3. Application key is generated if needed
4. Dependencies are installed

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

# Laravel artisan commands
docker-compose exec app php artisan migrate
docker-compose exec app php artisan make:controller UserController

# Access container shell
docker-compose exec app bash

# Database access
docker-compose exec mysql mysql -u [username] -p
```

## Troubleshooting

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

If .env configuration is lost:
- The start-container script automatically preserves and restores .env files
- Check `.env.backup` if issues occur during Laravel installation

## GitHub Repository Creation

### Automatic (via setup script)

The setup script can create repositories if GitHub CLI is configured:
```bash
gh auth login  # One-time setup
# Script will offer repository creation option
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
- Never commit .env files
- Use unique database passwords per project
- Keep credentials secure

### Docker Management
- Regular cleanup: `docker system prune`
- Monitor disk usage: `docker system df`

### Development
- Use migrations for database changes
- Regular backups with `db:dump` command
- Follow Laravel best practices

---

*This cookbook is maintained by the AlboradaIT development team. For updates, check the project-cookbooks repository.*
