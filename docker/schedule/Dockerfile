FROM php:8.4-fpm

# Install system tools and dependencies (same as main app)
RUN set -eux; \
    apt-get update && apt-get install -y \
        gnupg2 git unzip zip curl libpng-dev libonig-dev libxml2-dev libzip-dev \
        libcurl4-openssl-dev libssl-dev libpq-dev libicu-dev libsasl2-dev \
        pkg-config supervisor netcat-traditional procps cron \
        libfreetype6-dev libjpeg62-turbo-dev \
        && echo "=== System packages installed ===" \
        && docker-php-ext-configure gd --with-freetype --with-jpeg \
        && docker-php-ext-install -j$(nproc) \
            pdo pdo_mysql mbstring zip exif pcntl bcmath gd intl curl \
            xml sockets opcache \
        && echo "=== Core PHP extensions installed ===" \
        && pecl install redis mongodb \
        && docker-php-ext-enable redis mongodb \
        && echo "=== Redis and MongoDB extensions installed ===" \
        && apt-get clean && rm -rf /var/lib/apt/lists/*

# Verify extensions are loaded (debug checkpoint)
RUN php -m | grep -E "(pdo_mysql|mongodb|redis|pcntl)" \
    && echo "=== Scheduler extensions verified ===" \
    || (echo "=== CRITICAL: Missing scheduler extensions ===" && exit 1)

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy application code with proper permissions
COPY --chown=www-data:www-data . .

# Install PHP dependencies
RUN composer install --optimize-autoloader --no-scripts --no-interaction \
    && composer dump-autoload --optimize \
    && echo "=== Scheduler dependencies installed ==="

# Set proper permissions
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# PHP configuration optimized for scheduler
RUN { \
    echo 'memory_limit=256M'; \
    echo 'max_execution_time=0'; \
    echo 'pcntl.async_signals=1'; \
    echo 'opcache.enable_cli=1'; \
} > /usr/local/etc/php/conf.d/scheduler.ini

# Copy and set entrypoint
COPY docker/schedule/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php", "artisan", "schedule:work"]
