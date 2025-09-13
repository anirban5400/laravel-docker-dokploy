FROM php:8.4-fpm

# Install system tools and dependencies (with debug breakpoints)
RUN set -eux; \
    apt-get update && apt-get install -y \
        gnupg2 git unzip zip curl libpng-dev libonig-dev libxml2-dev libzip-dev \
        libcurl4-openssl-dev libssl-dev libpq-dev libicu-dev libsasl2-dev \
        pkg-config supervisor netcat-traditional procps \
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
RUN php -m | grep -E "(pdo_mysql|mongodb|redis|gd|intl|pcntl|sockets)" \
    && echo "=== All required extensions verified ===" \
    || (echo "=== CRITICAL: Missing extensions ===" && exit 1)

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Verify Composer installation
RUN composer --version && echo "=== Composer installed successfully ==="

WORKDIR /var/www/html

# Copy application code with proper permissions
COPY --chown=www-data:www-data . .

# Install PHP dependencies with debug output
RUN composer install --optimize-autoloader --no-scripts --no-interaction \
    && echo "=== Composer dependencies installed ===" \
    && composer dump-autoload --optimize \
    && echo "=== Autoloader optimized ==="

# Set proper permissions and cache Laravel configurations
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache \
    && echo "=== Permissions set ===" \
    && php artisan config:cache || echo 'Config cache skipped (no .env)' \
    && php artisan route:cache || echo 'Route cache skipped (no routes)' \
    && php artisan view:cache || echo 'View cache skipped (no views)' \
    && echo "=== Laravel optimizations completed ==="

# Create PHP configuration for production
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    echo 'memory_limit=256M'; \
    echo 'max_execution_time=300'; \
    echo 'upload_max_filesize=100M'; \
    echo 'post_max_size=100M'; \
} > /usr/local/etc/php/conf.d/laravel.ini

EXPOSE 9000

# Copy and set entrypoint
COPY docker/app/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
