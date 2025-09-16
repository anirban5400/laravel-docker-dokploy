#!/bin/sh

# Docker entrypoint script for Laravel application
set -e

echo "🚀 Starting Laravel application..."

# Wait for database to be ready with timeout
echo "⏳ Waiting for database connection..."

# Use our custom database wait script if available, otherwise fallback to simpler check
if [ -f "/var/www/scripts/wait-for-db.sh" ]; then
    /var/www/scripts/wait-for-db.sh
else
    MAX_ATTEMPTS=30
    ATTEMPT=0

    # Simple database connection test using PHP
    until php -r "
        try {
            \$host = getenv('DB_HOST') ?: 'db';
            \$port = getenv('DB_PORT') ?: '3306';
            \$database = getenv('DB_DATABASE') ?: 'laravel';
            \$username = getenv('DB_USERNAME') ?: 'laravel';
            \$password = getenv('DB_PASSWORD') ?: 'secret';
            \$pdo = new PDO(\"mysql:host=\$host;port=\$port;dbname=\$database\", \$username, \$password);
            \$pdo->query('SELECT 1');
            exit(0);
        } catch (Exception \$e) {
            exit(1);
        }
    " > /dev/null 2>&1; do
        ATTEMPT=$((ATTEMPT + 1))
        if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
            echo "❌ Database connection failed after $MAX_ATTEMPTS attempts (60 seconds)"
            echo "Please check your database configuration and ensure the database container is running"
            echo "Database configuration:"
            echo "  Host: ${DB_HOST:-db}"
            echo "  Port: ${DB_PORT:-3306}"
            echo "  Database: ${DB_DATABASE:-laravel}"
            echo "  Username: ${DB_USERNAME:-laravel}"
            exit 1
        fi
        echo "🔄 Database not ready, waiting 2 seconds... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
        sleep 2
    done

    echo "✅ Database connection established"
fi

# Show migration status (informational)
echo "📦 Checking migration status..."
if php artisan migrate:status --no-interaction --ansi; then
    echo "✅ Migration status checked"
else
    echo "⚠️  Could not retrieve migration status (this won't stop startup)"
fi

# Check MongoDB connectivity (ping)
echo "🧪 Checking MongoDB connection..."
php -d detect_unicode=0 -r '
    $uri = getenv("MONGODB_URI");
    if (!$uri) {
        $host = getenv("MONGODB_HOST") ?: "mongodb";
        $port = getenv("MONGODB_PORT") ?: "27017";
        $database = getenv("MONGODB_DATABASE") ?: "admin";
        $user = getenv("MONGODB_USERNAME");
        $pass = getenv("MONGODB_PASSWORD");
        if ($user && $pass) {
            $uri = "mongodb://{$user}:{$pass}@{$host}:{$port}/{$database}";
        } else {
            $uri = "mongodb://{$host}:{$port}/{$database}";
        }
    }
    try {
        $manager = new MongoDB\\Driver\\Manager($uri);
        $command = new MongoDB\\Driver\\Command(["ping" => 1]);
        $cursor = $manager->executeCommand("admin", $command);
        $response = current($cursor->toArray());
        if (isset($response->ok) && (float)$response->ok === 1.0) {
            echo "MongoDB ping: OK\n";
            exit(0);
        }
        echo "MongoDB ping: FAILED\n";
        exit(1);
    } catch (Throwable $e) {
        fwrite(STDERR, "MongoDB error: " . $e->getMessage() . "\n");
        exit(1);
    }
' >/dev/null 2>&1 && echo "✅ MongoDB reachable" || echo "⚠️  MongoDB not reachable"

# Check Redis installation and connectivity
echo "🧪 Checking Redis extension and connectivity..."
php -r '
    $hasExt = extension_loaded("redis");
    echo "extension_loaded(redis)=" . ($hasExt ? "yes" : "no") . "\n";
    $host = getenv("REDIS_HOST") ?: "127.0.0.1";
    $port = (int)(getenv("REDIS_PORT") ?: 6379);
    $password = getenv("REDIS_PASSWORD") ?: null;
    $database = (int)(getenv("REDIS_DB") ?: 0);
    $ok = false;
    try {
        if ($hasExt) {
            $r = new Redis();
            $r->connect($host, $port, 1.5);
            if ($password) { $r->auth($password); }
            if ($database) { $r->select($database); }
            $ok = ($r->ping() === "+PONG");
        } else {
            // Fallback to Predis if available via Composer
            @include "vendor/autoload.php";
            if (class_exists("Predis\\Client")) {
                $client = new Predis\\Client([
                    "scheme" => "tcp",
                    "host" => $host,
                    "port" => $port,
                    "password" => $password ?: null,
                    "database" => $database,
                ]);
                $ok = ($client->ping() == "+PONG");
            }
        }
    } catch (Throwable $e) {}
    echo $ok ? "redis_ping=OK\n" : "redis_ping=FAIL\n";
' 2>/dev/null | while IFS= read -r line; do echo "🔎 $line"; done

# List all loaded PHP extensions
echo "🧩 Loaded PHP extensions:"
php -r 'foreach (get_loaded_extensions() as $e) { echo $e, "\n"; }' 2>/dev/null | while IFS= read -r line; do echo "🔹 $line"; done

# Cache configuration and routes for better performance
echo "⚡ Optimizing application..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "🎉 Laravel application is ready!"

# Execute the main command
exec "$@"
