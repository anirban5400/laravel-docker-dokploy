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

# Ensure .env exists even if .env.example is not present
if [ ! -f .env ]; then
  echo "Creating minimal .env file..."
  {
    echo "APP_NAME=Laravel"
    echo "APP_ENV=${APP_ENV:-production}"
    echo "APP_DEBUG=${APP_DEBUG:-false}"
    echo "APP_URL=${APP_URL:-http://localhost}"
    if [ -n "$APP_KEY" ]; then
      echo "APP_KEY=$APP_KEY"
    else
      echo "APP_KEY="
    fi
  } > .env
fi

# If APP_KEY is not set in file and no APP_KEY env provided, generate one
if ! grep -q '^APP_KEY=' .env || [ -z "$(grep '^APP_KEY=' .env | cut -d'=' -f2)" ]; then
  if [ -n "$APP_KEY" ]; then
    # Insert provided APP_KEY into .env
    sed -i "s/^APP_KEY=.*/APP_KEY=$APP_KEY/" .env || echo "APP_KEY=$APP_KEY" >> .env
  else
    php artisan key:generate --force --ansi || true
  fi
fi

exec "$@"


