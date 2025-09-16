# Multi-stage Dockerfile for Laravel Web Application (Production)
# Stage 1: Build stage
FROM php:8.4-fpm-alpine AS builder

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    build-base \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    curl \
    openssl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        gd \
        pdo_mysql \
        zip \
        pcntl \
        posix \
        opcache \
    && apk add --no-cache --virtual .pecl-build-deps openssl-dev $PHPIZE_DEPS \
    && pecl install redis mongodb \
    && docker-php-ext-enable redis mongodb \
    && apk del .pecl-build-deps \
    && rm -rf /var/cache/apk/*

# Install Composer
COPY --from=composer:2.8 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www

# Copy composer files
COPY composer.json composer.lock ./

# Install PHP dependencies (production optimized)
RUN composer install --no-dev --no-scripts --no-autoloader --optimize-autoloader

# Copy application code
COPY . .

# Generate optimized autoloader (skip composer scripts to avoid running Artisan during build)
RUN composer dump-autoload --no-scripts --optimize --classmap-authoritative

# Set proper permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache

# Stage 2: Production stage
FROM php:8.4-fpm-alpine AS production

# Install runtime dependencies and PHP extensions
RUN apk add --no-cache \
    freetype \
    libjpeg-turbo \
    libpng \
    libzip \
    curl \
    openssl \
    ca-certificates \
    && apk add --no-cache --virtual .build-deps \
        build-base \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libzip-dev \
        openssl-dev \
        $PHPIZE_DEPS \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        gd \
        pdo_mysql \
        zip \
        pcntl \
        posix \
        opcache \
    && pecl install redis mongodb \
    && docker-php-ext-enable redis mongodb \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

# Production OPcache configuration
RUN echo 'opcache.memory_consumption=128' >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo 'opcache.interned_strings_buffer=8' >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo 'opcache.max_accelerated_files=4000' >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo 'opcache.revalidate_freq=2' >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo 'opcache.fast_shutdown=1' >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo 'opcache.enable_cli=0' >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo 'opcache.validate_timestamps=0' >> /usr/local/etc/php/conf.d/opcache.ini

# Production PHP configuration
RUN echo 'memory_limit=256M' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'max_execution_time=30' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'max_input_vars=3000' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'post_max_size=32M' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'upload_max_filesize=32M' >> /usr/local/etc/php/conf.d/php.ini \
    && echo 'expose_php=Off' >> /usr/local/etc/php/conf.d/php.ini

# Set working directory
WORKDIR /var/www

# Copy application from builder stage
COPY --from=builder --chown=www-data:www-data /var/www /var/www

# Prepare scripts directory and copy entrypoint + helper
RUN mkdir -p /var/www/scripts
COPY scripts/wait-for-db.sh /var/www/scripts/wait-for-db.sh
RUN chmod +x /var/www/scripts/wait-for-db.sh
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create necessary directories
RUN mkdir -p /var/www/storage/logs \
    && mkdir -p /var/www/storage/framework/cache \
    && mkdir -p /var/www/storage/framework/sessions \
    && mkdir -p /var/www/storage/framework/views \
    && mkdir -p /var/www/bootstrap/cache \
    && chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/api/health/simple || exit 1

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Start Laravel's built-in server
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
