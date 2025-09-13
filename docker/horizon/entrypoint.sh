#!/bin/bash
set -e

echo "==== Entrypoint: Starting Laravel Horizon ===="
echo "PHP Version:"
php -v
echo ""

echo "=== [BREAKPOINT] Checking Horizon Extensions ==="
php -m | grep -E "(pdo_mysql|mongodb|redis|pcntl|sockets)" || {
    echo "❌ CRITICAL: Missing required extensions for Horizon!"
    php -m | sort
    exit 1
}
echo "✅ All Horizon extensions are loaded"
echo ""

echo "=== [BREAKPOINT] Horizon Configuration Check ==="
echo "QUEUE_CONNECTION: ${QUEUE_CONNECTION:-NOT_SET}"
echo "REDIS_HOST: ${REDIS_HOST:-NOT_SET}"
echo "REDIS_PORT: ${REDIS_PORT:-NOT_SET}"
echo "HORIZON_DOMAIN: ${HORIZON_DOMAIN:-NOT_SET}"
echo ""

# Validate critical Horizon requirements
if [ "${QUEUE_CONNECTION}" != "redis" ]; then
    echo "❌ CRITICAL: Horizon requires QUEUE_CONNECTION=redis"
    exit 1
fi

if [ -z "${REDIS_HOST}" ] || [ -z "${REDIS_PORT}" ]; then
    echo "❌ CRITICAL: REDIS_HOST and REDIS_PORT must be set for Horizon!"
    exit 1
fi

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

# Wait for Redis (critical for Horizon)
echo "=== [BREAKPOINT] Waiting for Redis Queue Backend ==="
timeout=60
while ! nc -z "${REDIS_HOST}" "${REDIS_PORT}"; do
    echo "⏳ Waiting for Redis at ${REDIS_HOST}:${REDIS_PORT}... (${timeout}s remaining)"
    sleep 3
    timeout=$((timeout-3))
    if [ $timeout -le 0 ]; then
        echo "❌ CRITICAL: Horizon cannot start without Redis!"
        exit 1
    fi
done
echo "✅ Redis connection verified"

echo "=== [BREAKPOINT] Laravel Horizon Configuration ==="
if [ -f ".env" ]; then
    # Test Redis connection for Horizon
    echo "🔄 Testing Redis connection for Horizon..."
    if php artisan tinker --execute="
        try {
            \$redis = app('redis')->connection();
            \$redis->ping();
            echo 'Horizon Redis: ✅ Connected and responsive';
        } catch(Exception \$e) {
            echo 'Horizon Redis: ❌ ' . \$e->getMessage();
            exit(1);
        }" 2>/dev/null; then
        echo "Horizon Redis backend verified"
    else
        echo "❌ CRITICAL: Cannot connect to Redis for Horizon!"
        exit 1
    fi

    # Clear and optimize for Horizon
    echo "⚡ Optimizing for Horizon..."
    php artisan config:clear
    php artisan config:cache

    # Publish Horizon assets if needed
    echo "📦 Publishing Horizon assets..."
    php artisan horizon:publish || echo "Horizon assets already published or not needed"

    # Check Horizon configuration
    echo "⚙️ Horizon configuration:"
    if php artisan horizon:status >/dev/null 2>&1; then
        echo "✅ Horizon is properly configured"
    else
        echo "⚠️ Horizon status check failed (may be normal if not running yet)"
    fi

    # Show queue configuration
    echo "📊 Queue workers configuration:"
    php artisan queue:monitor --once || echo "Queue monitor completed"

else
    echo "❌ CRITICAL: No .env file found for Horizon!"
    exit 1
fi

echo ""
echo "🚀 [BREAKPOINT] Horizon checks completed!"
echo "📊 Starting Laravel Horizon Queue Manager..."
echo "🌐 Dashboard will be available at: http://${HORIZON_DOMAIN:-localhost}/horizon"
echo "⚙️ Horizon will manage queue workers automatically"
echo "===================================================="

# Ensure graceful shutdown handling
trap 'echo "🛑 Gracefully shutting down Horizon..."; php artisan horizon:terminate; kill -TERM $PID; wait $PID' TERM INT

# Start Horizon and capture PID for signal handling
exec "$@" &
PID=$!
wait $PID
