# Laravel Docker Dokploy Project

## 🏗️ **Professional Docker Structure for Laravel**

This project provides a **robust, debuggable, production-ready Docker setup** for Laravel with:
- ✅ **PHP 8.4** with all required extensions
- ✅ **External MySQL & MongoDB clusters** support
- ✅ **Queue Workers** with Redis backend
- ✅ **Task Scheduler** (Laravel Cron)
- ✅ **Reverb WebSocket Server** for real-time features
- ✅ **Horizon Queue Manager** with dashboard
- ✅ **Debug breakpoints** in all entrypoints
- ✅ **Health checks** for zero-downtime deployments
- ✅ **Dokploy-ready** with Traefik integration

## 📁 **Project Structure**

```
/
├── docker/
│   ├── app/                    # Main Laravel Application
│   │   ├── Dockerfile          # PHP-FPM with all extensions
│   │   └── entrypoint.sh       # Debug breakpoints & checks
│   ├── queue/                  # Queue Worker
│   │   ├── Dockerfile          # Optimized for background jobs
│   │   └── entrypoint.sh       # Queue-specific health checks
│   ├── schedule/               # Task Scheduler  
│   │   ├── Dockerfile          # Cron job processor
│   │   └── entrypoint.sh       # Scheduler validation
│   ├── reverb/                 # WebSocket Server
│   │   ├── Dockerfile          # Reverb WebSocket daemon
│   │   └── entrypoint.sh       # WebSocket connectivity tests
│   ├── horizon/                # Queue Manager
│   │   ├── Dockerfile          # Horizon dashboard & workers
│   │   └── entrypoint.sh       # Horizon-specific checks
│   └── nginx/
│       └── nginx.conf          # Production web server config
├── docker-compose.yml          # Full production setup
└── env.production.template     # Environment configuration template
```

## 🚀 **Quick Start**

### 1. **Configure Environment**
```bash
# Copy and edit the environment template
cp env.production.template .env

# Generate Laravel application key
php artisan key:generate

# Generate Reverb keys
php artisan reverb:install
```

### 2. **Set Your External Databases**
Edit `.env` with your external cluster details:
```env
# External MySQL Cluster
DB_HOST=your-mysql-cluster-host
DB_PORT=3306
DB_DATABASE=your-database
DB_USERNAME=your-username
DB_PASSWORD=your-password

# External MongoDB Cluster
MONGODB_HOST=your-mongodb-cluster-host
MONGODB_PORT=27017
MONGODB_DATABASE=your-mongo-db
MONGODB_USERNAME=your-mongo-username
MONGODB_PASSWORD=your-mongo-password
```

### 3. **Deploy on Dokploy**

#### **Option A: Docker Compose (Recommended)**
1. In Dokploy, create new service → **Docker Compose**
2. Point to your `docker-compose.yml`
3. Set environment variables from your `.env`
4. Deploy!

#### **Option B: Individual Services**
Deploy each service separately for maximum control:
- Main App: `docker/app/`
- Queue Worker: `docker/queue/`
- Scheduler: `docker/schedule/`
- Reverb: `docker/reverb/`
- Horizon: `docker/horizon/`

## 🔧 **What Each Service Does**

### **🏠 Main App (`app`)**
- **PHP 8.4-FPM** with all Laravel extensions
- **Nginx** web server for HTTP requests
- **Health checks** with database connectivity tests
- **Debug breakpoints** showing loaded extensions

### **⚙️ Queue Worker (`queue`)**
- **Background job processing** via `php artisan queue:work`
- **Redis connection validation**
- **Graceful shutdown handling**
- **Memory and timeout optimizations**

### **⏰ Scheduler (`schedule`)**
- **Laravel Cron** via `php artisan schedule:work`
- **Scheduled task validation**
- **Database connectivity checks**
- **Task listing for debugging**

### **📡 Reverb (`reverb`)**
- **WebSocket server** on port 6001
- **Real-time communication** for Laravel Echo
- **Port availability checks**
- **WebSocket connectivity tests**

### **📊 Horizon (`horizon`)**
- **Queue management dashboard** at `/horizon`
- **Worker monitoring and control**
- **Redis queue backend validation**
- **Auto-scaling queue workers**

### **🔴 Redis**
- **Queue backend** for jobs
- **Cache store** for performance
- **Session storage** for users
- **Persistent data** with append-only file

## 🐛 **Debug Features**

Each service includes **comprehensive debug breakpoints**:

```bash
# Example: Queue Worker Debug Output
==== Entrypoint: Starting Laravel Queue Worker ====
PHP Version: 8.4.x
=== [BREAKPOINT] Checking Queue Worker Extensions ===
✅ All queue worker extensions are loaded
=== [BREAKPOINT] Queue Configuration Check ===
QUEUE_CONNECTION: redis
REDIS_HOST: redis
=== [BREAKPOINT] Waiting for Redis Queue Backend ===
✅ Redis connection verified
🚀 [BREAKPOINT] Queue worker checks completed!
⚙️ Starting Laravel Queue Worker...
```

## 🌐 **Access Points**

After deployment, access your services:

- **🌐 Main App**: `https://your-domain.com`
- **📊 Horizon Dashboard**: `https://your-domain.com/horizon`
- **📡 WebSocket**: `wss://your-domain.com/app/{app-key}`
- **🔍 Health Check**: `https://your-domain.com/up`

## 🔍 **Monitoring & Health Checks**

All services include **comprehensive health checks**:

- **App**: PHP version and extension checks
- **Queue**: Job processing verification
- **Schedule**: Laravel CLI functionality
- **Reverb**: WebSocket port availability
- **Horizon**: Queue manager status
- **Redis**: Connection and ping tests

## 🛠️ **Troubleshooting**

### **Service Won't Start?**
Check the debug output in container logs:
```bash
docker logs laravel-app
docker logs laravel-queue
docker logs laravel-reverb
```

### **Database Connection Issues?**
Each entrypoint tests connectivity with timeout:
- **MySQL**: 60-second timeout with 5-second intervals
- **MongoDB**: 60-second timeout with 5-second intervals
- **Redis**: 30-second timeout with 3-second intervals

### **Missing Extensions?**
Each Dockerfile explicitly installs and verifies:
- **Core**: pdo_mysql, mongodb, redis, gd, intl
- **Process**: pcntl, sockets (for queues/WebSockets)
- **Performance**: opcache, bcmath, zip

### **Queue Jobs Not Processing?**
1. Check Redis connection in queue worker logs
2. Verify `QUEUE_CONNECTION=redis` in environment
3. Monitor Horizon dashboard for worker status

## 🎯 **Production Ready**

This setup includes all production best practices:

- ✅ **Multi-stage builds** for optimized images
- ✅ **Health checks** for zero-downtime deployments
- ✅ **Graceful shutdown** handling
- ✅ **Resource limits** and optimizations
- ✅ **Security headers** and configurations
- ✅ **Comprehensive logging** to stderr
- ✅ **Extension verification** at startup
- ✅ **Connection testing** with timeouts

## 📝 **Key Environment Variables**

```env
# Required for all services
PRODUCTION_DOMAIN=your-domain.com
APP_KEY=base64:your-app-key

# Database clusters (external)
DB_HOST=mysql-cluster-host
MONGODB_HOST=mongodb-cluster-host

# Reverb WebSocket
REVERB_APP_ID=your-reverb-id
REVERB_APP_KEY=your-reverb-key
REVERB_APP_SECRET=your-reverb-secret

# Redis (internal)
REDIS_PASSWORD=secure-redis-password
```

---

🎉 **You now have a professional, debuggable, production-ready Laravel setup with full WebSocket, queue, and scheduling support!**
