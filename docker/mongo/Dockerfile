# MongoDB Dockerfile for Laravel Application
FROM mongo:7.0

# Update packages and install security patches
RUN apt-get update && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /data/db

# Create necessary directories
RUN mkdir -p /data/db /data/configdb

# Set environment variables
ENV MONGO_INITDB_ROOT_USERNAME=admin
ENV MONGO_INITDB_ROOT_PASSWORD=password
ENV MONGO_INITDB_DATABASE=laravel

# Expose MongoDB port
EXPOSE 27017

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
    CMD mongosh --eval "db.adminCommand('ping')" || exit 1

# Start MongoDB with security improvements
CMD ["mongod", "--bind_ip_all", "--auth"]
