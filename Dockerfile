# Multi-stage build for Laravel with PHP 8.4
FROM php:8.4-fpm-alpine AS base

# Set working directory
WORKDIR /var/www/html

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    bash \
    curl \
    freetype-dev \
    git \
    icu-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    nginx \
    nodejs \
    npm \
    oniguruma-dev \
    postgresql-dev \
    supervisor \
    unzip \
    zip \
    autoconf \
    g++ \
    make \
    openssl-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        gd \
        intl \
        mbstring \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        xml \
        zip \
        pcntl \
        sockets

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install PECL extensions
RUN apk add --no-cache $PHPIZE_DEPS cyrus-sasl-dev \
    && pecl install redis mongodb \
    && docker-php-ext-enable redis mongodb \
    && apk del $PHPIZE_DEPS

# ================================
# Build stage
# ================================
FROM base AS build

# Copy composer files first for better layer caching
COPY composer.json composer.lock ./

# Install PHP dependencies (with dev dependencies for build)
RUN composer install --optimize-autoloader --no-interaction

# Copy package.json files for Node dependencies
COPY package*.json ./

# Install Node.js dependencies
RUN npm ci

# Copy application files
COPY . .

# Build assets
RUN npm run build

# Optimize autoloader for production
RUN composer dump-autoload --optimize --no-dev

# ================================
# Production stage
# ================================
FROM base AS production

# Copy configuration files
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/php.ini /usr/local/etc/php/php.ini

# Copy built application from build stage
COPY --from=build --chown=www-data:www-data /var/www/html /var/www/html

# Set proper permissions
RUN chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Create necessary directories
RUN mkdir -p /var/log/supervisor \
    && mkdir -p /run/nginx \
    && mkdir -p /var/www/html/storage/logs

# Health check for Dokploy zero downtime deployments
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/up || exit 1

# Expose ports (80 for web, 6001 for Reverb WebSockets)
EXPOSE 80 6001

# Start services using supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
