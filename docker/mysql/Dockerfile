# MySQL Dockerfile for Laravel Application
FROM mysql:8.0

# Update packages and install security patches
RUN apt-get update && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV MYSQL_DATABASE=laravel
ENV MYSQL_USER=laravel
ENV MYSQL_PASSWORD=secret
ENV MYSQL_ROOT_PASSWORD=root

# Create necessary directories
RUN mkdir -p /var/lib/mysql /var/run/mysqld

# Set proper permissions
RUN chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

# Expose MySQL port
EXPOSE 3306

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
    CMD mysqladmin ping -h localhost -u root -p$MYSQL_ROOT_PASSWORD || exit 1

# Start MySQL with security improvements
CMD ["mysqld", "--default-authentication-plugin=mysql_native_password", "--bind-address=0.0.0.0"]
