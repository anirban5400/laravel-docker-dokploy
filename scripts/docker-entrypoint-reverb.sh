#!/bin/sh
set -e

# Ensure storage and cache directories exist with proper permissions
mkdir -p /var/www/storage/logs \
         /var/www/storage/framework/cache \
         /var/www/storage/framework/sessions \
         /var/www/storage/framework/views \
         /var/www/bootstrap/cache

chown -R www-data:www-data /var/www || true
chmod -R 755 /var/www/storage /var/www/bootstrap/cache || true

# Generate app key if missing
if [ ! -f .env ]; then
  cp .env.example .env || true
fi

if ! grep -q '^APP_KEY=' .env || [ -z "$(grep '^APP_KEY=' .env | cut -d'=' -f2)" ]; then
  php artisan key:generate --force --ansi || true
fi

exec "$@"


