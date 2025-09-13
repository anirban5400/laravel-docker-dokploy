# Use the official PHP 8.2 FPM image as base
FROM php:8.2-fpm-alpine

# Set working directory
WORKDIR /var/www/html

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    build-base \
    curl \
    freetype-dev \
    git \
    icu-dev \
    jpeg-dev \
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
    openssl-dev \
    cyrus-sasl-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
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

# Install Redis extension
RUN apk add --no-cache $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del $PHPIZE_DEPS

# Install MongoDB extension
RUN apk add --no-cache $PHPIZE_DEPS \
    && pecl install mongodb \
    && docker-php-ext-enable mongodb \
    && apk del $PHPIZE_DEPS

# Copy composer files first for better layer caching
COPY composer.json composer.lock ./

# Install PHP dependencies first (better for Docker layer caching)
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# Copy package.json files for Node dependencies
COPY package*.json ./

# Install Node.js dependencies
RUN npm ci --only=production

# Copy application files
COPY . .

# Copy configuration files
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/php.ini /usr/local/etc/php/php.ini

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Run Composer scripts now that all files are copied
RUN composer dump-autoload --optimize

# Build assets
RUN npm run build \
    && npm cache clean --force

# Create necessary directories
RUN mkdir -p /var/log/supervisor \
    && mkdir -p /run/nginx \
    && mkdir -p /var/www/html/storage/logs

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost/up || exit 1

# Expose ports
EXPOSE 80 6001

# Start services using supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
