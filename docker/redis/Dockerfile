# Redis Dockerfile for Laravel Application
FROM redis:7.2-alpine

# Update packages and install security patches
RUN apk update && apk upgrade && apk add --no-cache dumb-init

# Set working directory
WORKDIR /data

# Create redis user and set permissions
RUN addgroup -g 1000 redis-user && \
    adduser -D -s /bin/sh -u 1000 -G redis-user redis-user

# Create data directory with proper permissions
RUN mkdir -p /data && \
    chown -R redis-user:redis-user /data

# Switch to redis user
USER redis-user

# Expose Redis port
EXPOSE 6379

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=5 \
    CMD redis-cli ping

# Start Redis server with persistence using dumb-init for proper signal handling
ENTRYPOINT ["dumb-init", "--"]
CMD ["redis-server", "--appendonly", "yes"]
