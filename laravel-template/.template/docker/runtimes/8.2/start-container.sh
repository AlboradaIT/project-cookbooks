#!/usr/bin/env bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Laravel container...${NC}"

# Check if Laravel is installed
if [ ! -f "/var/www/html/artisan" ]; then
    echo -e "${YELLOW}Laravel not found. Installing latest Laravel...${NC}"
    
    # Backup existing .env file if it exists
    if [ -f "/var/www/html/.env" ]; then
        echo -e "${YELLOW}Backing up existing .env file...${NC}"
        cp /var/www/html/.env /var/www/html/.env.backup
    fi
    
    # Create Laravel project as sail user
    gosu sail composer create-project laravel/laravel /tmp/laravel-temp --prefer-dist
    
    # Move Laravel files to working directory
    cp -r /tmp/laravel-temp/. /var/www/html/
    rm -rf /tmp/laravel-temp
    
    # Restore backed up .env file if it existed
    if [ -f "/var/www/html/.env.backup" ]; then
        echo -e "${YELLOW}Restoring original .env file...${NC}"
        mv /var/www/html/.env.backup /var/www/html/.env
    fi
    
    # Fix ownership
    chown -R sail:sail /var/www/html
    
    echo -e "${GREEN}Laravel installed successfully!${NC}"
    
    # Generate application key if not set
    if [ -f "/var/www/html/.env" ] && ! grep -q "APP_KEY=base64:" /var/www/html/.env; then
        echo -e "${YELLOW}Generating application key...${NC}"
        cd /var/www/html && gosu sail php artisan key:generate
    fi
else
    echo -e "${GREEN}Laravel installation found.${NC}"
fi

# Change to Laravel directory
cd /var/www/html

# Install/update dependencies if composer.json exists
if [ -f "composer.json" ]; then
    echo -e "${YELLOW}Installing/updating Composer dependencies...${NC}"
    gosu sail composer install --optimize-autoloader
fi

echo -e "${GREEN}Container initialization complete!${NC}"

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
