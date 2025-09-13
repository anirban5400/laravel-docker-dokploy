#!/bin/bash
set -e

echo "==== Entrypoint: Starting Laravel Scheduler ===="
echo "PHP Version:"
php -v
echo ""

echo "=== [BREAKPOINT] Checking Scheduler Extensions ==="
php -m | grep -E "(pdo_mysql|mongodb|redis|pcntl)" || {
    echo "❌ CRITICAL: Missing required extensions for scheduler!"
    php -m | sort
    exit 1
}
echo "✅ All scheduler extensions are loaded"
echo ""

echo "=== [BREAKPOINT] Scheduler Configuration Check ==="
echo "APP_ENV: ${APP_ENV:-NOT_SET}"
echo "DB_HOST: ${DB_HOST:-NOT_SET}"
echo "REDIS_HOST: ${REDIS_HOST:-NOT_SET}"
echo ""

# Wait for database connections
if [ -n "${DB_HOST}" ] && [ -n "${DB_PORT}" ]; then
    echo "=== [BREAKPOINT] Waiting for MySQL Database ==="
    timeout=60
    while ! nc -z "${DB_HOST}" "${DB_PORT}"; do
        echo "⏳ Waiting for MySQL at ${DB_HOST}:${DB_PORT}... (${timeout}s remaining)"
        sleep 5
        timeout=$((timeout-5))
        if [ $timeout -le 0 ]; then
            echo "❌ TIMEOUT: Could not connect to MySQL"
            exit 1
        fi
    done
    echo "✅ MySQL connection verified"
fi

# Wait for Redis (may be needed for cache/sessions in scheduled tasks)
if [ -n "${REDIS_HOST}" ] && [ -n "${REDIS_PORT}" ]; then
    echo "=== [BREAKPOINT] Waiting for Redis Cache ==="
    timeout=30
    while ! nc -z "${REDIS_HOST}" "${REDIS_PORT}"; do
        echo "⏳ Waiting for Redis at ${REDIS_HOST}:${REDIS_PORT}... (${timeout}s remaining)"
        sleep 3
        timeout=$((timeout-3))
        if [ $timeout -le 0 ]; then
            echo "⚠️ WARNING: Redis not available (scheduler may still work)"
            break
        fi
    done
    echo "✅ Redis connection verified"
fi

echo "=== [BREAKPOINT] Laravel Scheduler Configuration ==="
if [ -f ".env" ]; then
    # Test basic Laravel functionality
    echo "🔄 Testing Laravel configuration..."
    if php artisan --version >/dev/null 2>&1; then
        echo "✅ Laravel CLI is functional"
    else
        echo "❌ CRITICAL: Laravel CLI is not working!"
        exit 1
    fi

    # Clear and cache configurations
    echo "⚡ Optimizing for scheduled tasks..."
    php artisan config:clear
    php artisan config:cache

    # Show scheduled tasks
    echo "📅 Registered scheduled tasks:"
    php artisan schedule:list || echo "No scheduled tasks found or schedule:list not available"

else
    echo "❌ CRITICAL: No .env file found for scheduler!"
    exit 1
fi

echo ""
echo "🚀 [BREAKPOINT] Scheduler checks completed!"
echo "⏰ Starting Laravel Task Scheduler..."
echo "📅 Scheduler will check for tasks every minute"
echo "===================================================="

# Ensure graceful shutdown handling
trap 'echo "🛑 Gracefully shutting down scheduler..."; kill -TERM $PID; wait $PID' TERM INT

# Start the scheduler and capture PID for signal handling
exec "$@" &
PID=$!
wait $PID
