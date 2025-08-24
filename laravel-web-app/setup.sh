#!/bin/bash

# Laravel Docker Template Setup Script
# Usage: ./setup.sh [project-name]

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
    echo "Usage: $0 <project-name> [db-name] [domain] [db-password]"
    echo "Example: $0 my-awesome-app my_awesome_db my-awesome-app.local mypassword123"
    exit 1
fi

PROJECT_NAME="$1"
DB_NAME="${2:-$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_\|_$//g')}"
APP_DOMAIN="${3:-$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g').local}"
DB_PASSWORD="${4:-$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)}"
PROJECTS_DIR="$HOME/projects"

# Create kebab-case version for directory/container names
KEBAB_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

# Note: Project name can be any format, we normalize it for containers/databases as needed

print_status "Setting up Laravel project: $PROJECT_NAME"

# Create projects directory if it doesn't exist
mkdir -p "$PROJECTS_DIR"
cd "$PROJECTS_DIR"

# Check if project directory already exists
if [ -d "$KEBAB_NAME" ]; then
    print_error "Directory '$KEBAB_NAME' already exists!"
    exit 1
fi

# Copy template files
print_status "Setting up project from local template..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Create project directory
mkdir -p "$KEBAB_NAME"
cd "$KEBAB_NAME"

# Copy only the template files (much safer)
print_status "Copying template files..."
cp -r "$SCRIPT_DIR/.template/"* .
cp -r "$SCRIPT_DIR/.template/".* . 2>/dev/null || true

# Remove template files and git history (they're already copied)
# rm -rf .template .git setup.sh setup-interactive.sh TEAM_WORKSPACE_SETUP.md AGENT_SETUP_INSTRUCTIONS.md

# Make scripts executable
chmod +x docker/runtimes/8.2/start-container.sh

# Initialize new git repository
git init
print_success "Git repository initialized"

# Generate secure database password
# DB_PASSWORD=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)

# Normalize app name for database
# DB_NAME=$(echo "$PROJECT_NAME" | tr '-' '_')
# APP_DOMAIN="$PROJECT_NAME.local"

# Create kebab-case version for directory/container names (already defined above)
# KEBAB_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

print_status "Configuring environment variables..."

# Update .env file
cp .env.example .env
sed -i "s/APP_NAME=\"Laravel Application\"/APP_NAME=\"$PROJECT_NAME\"/" .env
sed -i "s/DB_DATABASE=laravel/DB_DATABASE=$DB_NAME/" .env
sed -i "s/DB_USERNAME=laravel/DB_USERNAME=$DB_NAME/" .env
sed -i "s/DB_PASSWORD=/DB_PASSWORD=$DB_PASSWORD/" .env

# Process docker-compose.stub.yml to docker-compose.yml
sed "s/{{APP_DOMAIN}}/$APP_DOMAIN/g" docker-compose.stub.yml > docker-compose.yml
rm docker-compose.stub.yml

print_success "Environment configured"
print_status "Project: $PROJECT_NAME"
print_status "Directory: $KEBAB_NAME"
print_status "Database: $DB_NAME"
print_status "Domain: $APP_DOMAIN" 
print_status "Password: $DB_PASSWORD"

# Check if Traefik is running
if ! docker network ls | grep -q traefik; then
    print_warning "Traefik network not found. Setting up Traefik..."
    
    # Create Traefik directory and copy configuration
    mkdir -p "$HOME/shared-services/traefik"
    cp docker/reverse-proxy/traefik/docker-compose.yml "$HOME/shared-services/traefik/"
    
    print_status "Traefik configuration copied to ~/shared-services/traefik/"
    print_status "To start Traefik: cd ~/shared-services/traefik && docker network create traefik && docker-compose up -d"
fi

print_success "Project setup complete!"
echo
print_status "Next steps:"
echo "1. cd $PROJECTS_DIR/$KEBAB_NAME"
echo "2. docker-compose up -d"
echo "3. Wait for Laravel installation to complete"
echo "4. Open https://$APP_DOMAIN in your browser"
echo
print_status "Optional: Create GitHub repository"
echo "gh repo create AlboradaIT/$KEBAB_NAME --private"
