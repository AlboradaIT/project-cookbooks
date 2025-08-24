#!/bin/bash

# Laravel Docker Project Creation Script
# This script can be run directly via curl without cloning the repository
# Usage: curl -fsSL https://raw.githubusercontent.com/AlboradaIT/project-cookbooks/main/create-project.sh | bash -s -- "Project Name" [db-name] [domain] [password]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if project name is provided
if [ -z "$1" ]; then
    print_error "Project name is required!"
    echo "Usage: curl -fsSL https://raw.githubusercontent.com/AlboradaIT/project-cookbooks/main/create-project.sh | bash -s -- \"Project Name\" [db-name] [domain] [password]"
    echo "Example: curl -fsSL https://raw.githubusercontent.com/AlboradaIT/project-cookbooks/main/create-project.sh | bash -s -- \"My Awesome App\" my_awesome_db my-awesome-app.local mypassword123"
    exit 1
fi

PROJECT_NAME="$1"
DB_NAME="${2:-$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_\|_$//g')}"
APP_DOMAIN="${3:-$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g').local}"
DB_PASSWORD="${4:-$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)}"
PROJECTS_DIR="$HOME/projects"

# Create kebab-case version for directory/container names
KEBAB_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

print_status "Setting up Laravel project: $PROJECT_NAME"

# Create projects directory if it doesn't exist
mkdir -p "$PROJECTS_DIR"
cd "$PROJECTS_DIR"

# Check if project directory already exists
if [ -d "$KEBAB_NAME" ]; then
    print_error "Directory '$KEBAB_NAME' already exists!"
    exit 1
fi

# Create a unique temporary directory to avoid conflicts
TEMP_DIR=$(mktemp -d)
print_status "Using temporary directory: $TEMP_DIR"

# Clone cookbook repository to the temporary location
print_status "Cloning cookbook repository..."
git clone https://github.com/AlboradaIT/project-cookbooks.git "$TEMP_DIR/project-cookbooks"

# Create project directory
print_status "Creating project directory: $KEBAB_NAME"
mkdir -p "$KEBAB_NAME"
cd "$KEBAB_NAME"

# Copy template files from the cloned repository
print_status "Copying template files..."
TEMPLATE_DIR="$TEMP_DIR/project-cookbooks/laravel-web-app/.template"

if [ ! -d "$TEMPLATE_DIR" ]; then
    print_error "Template directory not found: $TEMPLATE_DIR"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Copy all template files including hidden ones
cp -r "$TEMPLATE_DIR/"* . 2>/dev/null || true
cp -r "$TEMPLATE_DIR/".* . 2>/dev/null || true

# Make scripts executable
chmod +x docker/runtimes/8.2/start-container.sh

print_status "Configuring environment variables..."

# Update .env file
if [ -f ".env.example" ]; then
    cp .env.example .env
    sed -i "s/APP_NAME=\"Laravel Application\"/APP_NAME=\"$PROJECT_NAME\"/" .env
    sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$DB_NAME/" .env
    sed -i "s/DB_USERNAME=laravel/DB_USERNAME=$DB_NAME/" .env
    sed -i "s/DB_PASSWORD=/DB_PASSWORD=$DB_PASSWORD/" .env
else
    print_error ".env.example not found in template"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Process docker-compose.stub.yml to docker-compose.yml
if [ -f "docker-compose.stub.yml" ]; then
    sed "s/{{APP_DOMAIN}}/$APP_DOMAIN/g" docker-compose.stub.yml > docker-compose.yml
    rm docker-compose.stub.yml
else
    print_error "docker-compose.stub.yml not found in template"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Pre-install Laravel using the project's container image
print_status "Building container image for Laravel installation..."
docker build -t "temp-laravel-installer-$KEBAB_NAME" -f docker/runtimes/8.2/Dockerfile .

print_status "Installing Laravel using project container..."
docker run --rm \
    --entrypoint="" \
    -v "$(pwd):/var/www/html" \
    -w /var/www/html \
    -e WWWUSER=$(id -u) \
    -e WWWGROUP=$(id -g) \
    "temp-laravel-installer-$KEBAB_NAME" \
    bash -c "
        # Install Laravel in temp location
        composer create-project laravel/laravel /tmp/laravel --prefer-dist &&
        
        # Copy Laravel files to working directory, preserving .env
        cp .env /tmp/laravel/.env &&
        cp -r /tmp/laravel/. /var/www/html/ &&
        
        # Set correct ownership
        chown -R \$WWWUSER:\$WWWGROUP /var/www/html &&
        
        # Generate application key
        php artisan key:generate
    "

# Clean up temp image
docker rmi "temp-laravel-installer-$KEBAB_NAME"

# Initialize new git repository
git init
print_success "Git repository initialized"

# Clean up temporary files
print_status "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

print_success "Environment configured"
print_status "Project: $PROJECT_NAME"
print_status "Directory: $KEBAB_NAME"
print_status "Database: $DB_NAME"
print_status "Domain: $APP_DOMAIN" 
print_status "Password: $DB_PASSWORD"

# Check if Traefik is running
if ! docker network ls | grep -q traefik; then
    print_warning "Traefik network not found. You may need to set up Traefik..."
    print_status "To create Traefik network: docker network create traefik"
fi

print_success "Project setup complete!"
echo
print_status "Laravel has been pre-installed and is ready to use!"
print_status "Next steps:"
echo "1. cd $PROJECTS_DIR/$KEBAB_NAME"
echo "2. docker-compose up -d"
echo "3. Open https://$APP_DOMAIN in your browser"
echo
print_status "You can now use 'sail' commands immediately:"
echo "sail artisan --version"
echo "sail tinker"
echo "sail test"
echo
print_status "Optional: Create GitHub repository"
echo "gh repo create AlboradaIT/$KEBAB_NAME --private"
