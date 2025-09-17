# Multi-stage Dockerfile for Laravel Queue Worker (Production)
# Stage 1: Build stage
FROM php:8.4-cli-alpine3.19 AS builder

# Install system dependencies and PHP extensions
RUN apk update && apk upgrade && apk add --no-cache \
    build-base \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    curl \
    openssl \
    dumb-init \
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
COPY ../../composer.json ../../composer.lock ./

# Install PHP dependencies (production optimized)
RUN composer install --no-dev --no-scripts --no-autoloader --optimize-autoloader

# Copy application code
COPY ../../ .

# Generate optimized autoloader (skip composer scripts to avoid running Artisan during build)
RUN composer dump-autoload --no-scripts --optimize --classmap-authoritative

# Set proper permissions
RUN chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache

# Stage 2: Production stage
FROM php:8.4-cli-alpine3.19 AS production

# Install runtime dependencies and PHP extensions
RUN apk update && apk upgrade && apk add --no-cache \
    freetype \
    libjpeg-turbo \
    libpng \
    libzip \
    openssl \
    ca-certificates \
    zstd-libs \
    cyrus-sasl \
    snappy \
    libsasl \
    dumb-init \
    && apk add --no-cache --virtual .build-deps \
        build-base \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libzip-dev \
        openssl-dev \
        zlib-dev \
        zstd-dev \
        cyrus-sasl-dev \
        pkgconfig \
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
    && echo 'opcache.enable_cli=1' >> /usr/local/etc/php/conf.d/opcache.ini

# Production PHP configuration for queue worker
RUN echo 'memory_limit=256M' >> /usr/local/etc/php/conf.d/php.ini

# Set working directory
WORKDIR /var/www

# Copy application from builder stage
COPY --from=builder --chown=www-data:www-data /var/www /var/www

# Copy entrypoint script from scripts
COPY docker-entrypoint-queue.sh /usr/local/bin/docker-entrypoint-queue.sh
RUN chmod +x /usr/local/bin/docker-entrypoint-queue.sh

# Create necessary directories
RUN mkdir -p /var/www/storage/logs \
    && mkdir -p /var/www/storage/framework/cache \
    && mkdir -p /var/www/storage/framework/sessions \
    && mkdir -p /var/www/storage/framework/views \
    && mkdir -p /var/www/bootstrap/cache \
    && chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www/storage \
    && chmod -R 755 /var/www/bootstrap/cache

# Health check for queue worker
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep -f "php artisan queue:work" || exit 1

# Set entrypoint with dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--", "/usr/local/bin/docker-entrypoint-queue.sh"]

# Start queue worker
CMD ["php", "artisan", "queue:work", "--verbose", "--sleep=3", "--tries=3"]
