#!/bin/bash
set -e

echo "==== Entrypoint: Starting Laravel Reverb WebSocket Server ===="
echo "PHP Version:"
php -v
echo ""

echo "=== [BREAKPOINT] Checking Reverb WebSocket Extensions ==="
php -m | grep -E "(pdo_mysql|mongodb|redis|sockets|pcntl)" || {
    echo "❌ CRITICAL: Missing required extensions for Reverb WebSocket server!"
    php -m | sort
    exit 1
}
echo "✅ All Reverb WebSocket extensions are loaded"
echo ""

echo "=== [BREAKPOINT] Reverb Configuration Check ==="
echo "BROADCAST_CONNECTION: ${BROADCAST_CONNECTION:-NOT_SET}"
echo "REVERB_APP_ID: ${REVERB_APP_ID:-NOT_SET}"
echo "REVERB_APP_KEY: ${REVERB_APP_KEY:-NOT_SET}"
echo "REVERB_APP_SECRET: ${REVERB_APP_SECRET:-NOT_SET}"
echo "REVERB_HOST: ${REVERB_HOST:-NOT_SET}"
echo "REVERB_PORT: ${REVERB_PORT:-NOT_SET}"
echo "REVERB_SCHEME: ${REVERB_SCHEME:-NOT_SET}"
echo ""

# Validate critical Reverb environment variables
if [ -z "${REVERB_APP_KEY}" ] || [ -z "${REVERB_APP_SECRET}" ] || [ -z "${REVERB_APP_ID}" ]; then
    echo "❌ CRITICAL: REVERB_APP_KEY, REVERB_APP_SECRET, and REVERB_APP_ID must be set!"
    exit 1
fi

# Wait for database connections (may be needed for authentication)
if [ -n "${DB_HOST}" ] && [ -n "${DB_PORT}" ]; then
    echo "=== [BREAKPOINT] Waiting for MySQL Database ==="
    timeout=60
    while ! nc -z "${DB_HOST}" "${DB_PORT}"; do
        echo "⏳ Waiting for MySQL at ${DB_HOST}:${DB_PORT}... (${timeout}s remaining)"
        sleep 5
        timeout=$((timeout-5))
        if [ $timeout -le 0 ]; then
            echo "⚠️ WARNING: Could not connect to MySQL (Reverb may still work)"
            break
        fi
    done
    if nc -z "${DB_HOST}" "${DB_PORT}"; then
        echo "✅ MySQL connection verified"
    fi
fi

# Wait for Redis (may be used for broadcasting/presence channels)
if [ -n "${REDIS_HOST}" ] && [ -n "${REDIS_PORT}" ]; then
    echo "=== [BREAKPOINT] Waiting for Redis Broadcasting Backend ==="
    timeout=30
    while ! nc -z "${REDIS_HOST}" "${REDIS_PORT}"; do
        echo "⏳ Waiting for Redis at ${REDIS_HOST}:${REDIS_PORT}... (${timeout}s remaining)"
        sleep 3
        timeout=$((timeout-3))
        if [ $timeout -le 0 ]; then
            echo "⚠️ WARNING: Redis not available (may affect broadcasting features)"
            break
        fi
    done
    if nc -z "${REDIS_HOST}" "${REDIS_PORT}"; then
        echo "✅ Redis connection verified"
    fi
fi

echo "=== [BREAKPOINT] Laravel Reverb Configuration ==="
if [ -f ".env" ]; then
    # Test Laravel Reverb configuration
    echo "🔄 Testing Reverb configuration..."

    # Clear and cache configurations
    echo "⚡ Optimizing for WebSocket server..."
    php artisan config:clear
    php artisan config:cache

    # Check if Reverb is properly configured
    if php artisan reverb:ping >/dev/null 2>&1; then
        echo "✅ Reverb configuration is valid"
    else
        echo "⚠️ WARNING: Reverb ping failed (server may still start)"
    fi

    # Show Reverb configuration
    echo "📡 Reverb server will start on:"
    echo "   - Host: 0.0.0.0"
    echo "   - Port: 6001"
    echo "   - App ID: ${REVERB_APP_ID}"
    echo "   - Public Host: ${REVERB_HOST:-localhost}"
    echo "   - Scheme: ${REVERB_SCHEME:-http}"

else
    echo "❌ CRITICAL: No .env file found for Reverb server!"
    exit 1
fi

# Check if port 6001 is available
echo "=== [BREAKPOINT] Port Availability Check ==="
if netstat -tuln | grep -q ":6001 "; then
    echo "❌ CRITICAL: Port 6001 is already in use!"
    netstat -tuln | grep ":6001"
    exit 1
else
    echo "✅ Port 6001 is available"
fi

echo ""
echo "🚀 [BREAKPOINT] Reverb WebSocket server checks completed!"
echo "📡 Starting Laravel Reverb WebSocket Server..."
echo "🌐 Server will be available on 0.0.0.0:6001"
echo "🔗 WebSocket endpoint: ws://0.0.0.0:6001/app/${REVERB_APP_KEY}"
echo "===================================================="

# Ensure graceful shutdown handling
trap 'echo "🛑 Gracefully shutting down Reverb server..."; kill -TERM $PID; wait $PID' TERM INT

# Start Reverb and capture PID for signal handling
exec "$@" &
PID=$!
wait $PID
