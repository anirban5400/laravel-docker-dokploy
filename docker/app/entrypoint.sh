#!/bin/bash
set -e

echo "==== Entrypoint: Starting Laravel Main App ===="
echo "PHP Version:"
php -v
echo ""

echo "=== [BREAKPOINT] Checking Required PHP Extensions ==="
php -m | grep -E "(pdo_mysql|mongodb|redis|gd|intl|pcntl|sockets|opcache)" || {
    echo "❌ CRITICAL: Missing required PHP extensions!"
    php -m | sort
    exit 1
}
echo "✅ All required PHP extensions are loaded"
echo ""

echo "=== [BREAKPOINT] Environment Variables Check ==="
echo "DB_HOST: ${DB_HOST:-NOT_SET}"
echo "DB_PORT: ${DB_PORT:-NOT_SET}"
echo "MONGODB_HOST: ${MONGODB_HOST:-NOT_SET}"
echo "MONGODB_PORT: ${MONGODB_PORT:-NOT_SET}"
echo "REDIS_HOST: ${REDIS_HOST:-NOT_SET}"
echo ""

# Wait for external MySQL cluster
if [ -n "${DB_HOST}" ] && [ -n "${DB_PORT}" ]; then
    echo "=== [BREAKPOINT] Waiting for External MySQL Cluster ==="
    timeout=60
    while ! nc -z "${DB_HOST}" "${DB_PORT}"; do
        echo "⏳ Waiting for MySQL at ${DB_HOST}:${DB_PORT}... (${timeout}s remaining)"
        sleep 5
        timeout=$((timeout-5))
        if [ $timeout -le 0 ]; then
            echo "❌ TIMEOUT: Could not connect to MySQL cluster"
            exit 1
        fi
    done
    echo "✅ MySQL cluster connection verified"
else
    echo "⚠️ MySQL connection details not provided, skipping check"
fi

# Wait for external MongoDB cluster
if [ -n "${MONGODB_HOST}" ] && [ -n "${MONGODB_PORT}" ]; then
    echo "=== [BREAKPOINT] Waiting for External MongoDB Cluster ==="
    timeout=60
    while ! nc -z "${MONGODB_HOST}" "${MONGODB_PORT}"; do
        echo "⏳ Waiting for MongoDB at ${MONGODB_HOST}:${MONGODB_PORT}... (${timeout}s remaining)"
        sleep 5
        timeout=$((timeout-5))
        if [ $timeout -le 0 ]; then
            echo "❌ TIMEOUT: Could not connect to MongoDB cluster"
            exit 1
        fi
    done
    echo "✅ MongoDB cluster connection verified"
else
    echo "⚠️ MongoDB connection details not provided, skipping check"
fi

# Wait for Redis if configured
if [ -n "${REDIS_HOST}" ] && [ -n "${REDIS_PORT}" ]; then
    echo "=== [BREAKPOINT] Waiting for Redis ==="
    timeout=30
    while ! nc -z "${REDIS_HOST}" "${REDIS_PORT}"; do
        echo "⏳ Waiting for Redis at ${REDIS_HOST}:${REDIS_PORT}... (${timeout}s remaining)"
        sleep 3
        timeout=$((timeout-3))
        if [ $timeout -le 0 ]; then
            echo "❌ TIMEOUT: Could not connect to Redis"
            exit 1
        fi
    done
    echo "✅ Redis connection verified"
fi

echo "=== [BREAKPOINT] Laravel Application Checks ==="
# Test database connections if .env exists
if [ -f ".env" ]; then
    echo "📋 Running Laravel configuration checks..."

    # Test MySQL connection
    if php artisan tinker --execute="try { DB::connection('mysql')->getPdo(); echo 'MySQL: ✅ Connected'; } catch(Exception \$e) { echo 'MySQL: ❌ ' . \$e->getMessage(); }" 2>/dev/null; then
        echo "Database connection test completed"
    fi

    # Test MongoDB connection (if configured)
    if php artisan tinker --execute="try { DB::connection('mongodb')->getMongoClient(); echo 'MongoDB: ✅ Connected'; } catch(Exception \$e) { echo 'MongoDB: ❌ ' . \$e->getMessage(); }" 2>/dev/null; then
        echo "MongoDB connection test completed"
    fi

    # Run migrations if needed
    echo "🔄 Running database migrations..."
    php artisan migrate --force || echo "⚠️ Migrations failed or not needed"

    # Clear and cache configurations
    echo "⚡ Optimizing Laravel..."
    php artisan config:clear
    php artisan config:cache
    php artisan route:clear
    php artisan route:cache || echo "Route cache skipped"
    php artisan view:clear
    php artisan view:cache || echo "View cache skipped"

else
    echo "⚠️ No .env file found, skipping Laravel-specific checks"
fi

echo ""
echo "🚀 [BREAKPOINT] All checks completed successfully!"
echo "🎯 Starting PHP-FPM for Laravel Main Application..."
echo "===================================================="

# Start the main command
exec "$@"
