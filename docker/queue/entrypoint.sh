#!/bin/bash
set -e

echo "==== Entrypoint: Starting Laravel Queue Worker ===="
echo "PHP Version:"
php -v
echo ""

echo "=== [BREAKPOINT] Checking Queue Worker Extensions ==="
php -m | grep -E "(pdo_mysql|mongodb|redis|pcntl|sockets)" || {
    echo "❌ CRITICAL: Missing required extensions for queue worker!"
    php -m | sort
    exit 1
}
echo "✅ All queue worker extensions are loaded"
echo ""

echo "=== [BREAKPOINT] Queue Configuration Check ==="
echo "QUEUE_CONNECTION: ${QUEUE_CONNECTION:-NOT_SET}"
echo "REDIS_HOST: ${REDIS_HOST:-NOT_SET}"
echo "REDIS_PORT: ${REDIS_PORT:-NOT_SET}"
echo ""

# Wait for database connections (same as main app)
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

# Wait for Redis (critical for queue workers)
if [ -n "${REDIS_HOST}" ] && [ -n "${REDIS_PORT}" ]; then
    echo "=== [BREAKPOINT] Waiting for Redis Queue Backend ==="
    timeout=60
    while ! nc -z "${REDIS_HOST}" "${REDIS_PORT}"; do
        echo "⏳ Waiting for Redis at ${REDIS_HOST}:${REDIS_PORT}... (${timeout}s remaining)"
        sleep 3
        timeout=$((timeout-3))
        if [ $timeout -le 0 ]; then
            echo "❌ CRITICAL: Queue worker cannot start without Redis!"
            exit 1
        fi
    done
    echo "✅ Redis connection verified"
else
    echo "❌ CRITICAL: REDIS_HOST and REDIS_PORT must be set for queue worker!"
    exit 1
fi

echo "=== [BREAKPOINT] Laravel Queue Configuration ==="
if [ -f ".env" ]; then
    # Test Redis connection for queues
    echo "🔄 Testing Redis queue connection..."
    if php artisan tinker --execute="
        try {
            \$redis = app('redis')->connection();
            \$redis->ping();
            echo 'Redis Queue: ✅ Connected and responsive';
        } catch(Exception \$e) {
            echo 'Redis Queue: ❌ ' . \$e->getMessage();
            exit(1);
        }" 2>/dev/null; then
        echo "Queue backend connection verified"
    else
        echo "❌ CRITICAL: Cannot connect to queue backend!"
        exit 1
    fi

    # Clear and optimize for queue processing
    echo "⚡ Optimizing for queue processing..."
    php artisan config:clear
    php artisan config:cache

    # Check if we can see any queued jobs
    echo "📊 Queue status check..."
    php artisan queue:monitor --once || echo "Queue monitor check completed"

else
    echo "❌ CRITICAL: No .env file found for queue worker!"
    exit 1
fi

echo ""
echo "🚀 [BREAKPOINT] Queue worker checks completed!"
echo "⚙️ Starting Laravel Queue Worker..."
echo "🔄 Worker will process jobs with 3 retries, 300s timeout, 256MB memory limit"
echo "===================================================="

# Ensure graceful shutdown handling
trap 'echo "🛑 Gracefully shutting down queue worker..."; kill -TERM $PID; wait $PID' TERM INT

# Start the queue worker and capture PID for signal handling
exec "$@" &
PID=$!
wait $PID
