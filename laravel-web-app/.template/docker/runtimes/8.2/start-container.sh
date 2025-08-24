#!/usr/bin/env bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Laravel container...${NC}"

# Set the user id to the host user id if provided
if [ ! -z "$WWWUSER" ]; then
    usermod -u $WWWUSER sail
fi

# Get the home directory of the 'sail' user
SAIL_HOME=$(getent passwd sail | cut -d: -f6)

# Ensure the Composer's global directory exists and has the correct permissions
gosu sail mkdir -p $SAIL_HOME/.composer
chmod -R ugo+rw $SAIL_HOME/.composer

# Change to Laravel directory
cd /var/www/html

echo -e "${GREEN}Laravel container ready!${NC}"

# Start supervisor
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
