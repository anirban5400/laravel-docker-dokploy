# Laravel Docker Dokploy

A complete Laravel application with **Reverb (WebSockets)**, **Horizon (Queue Management)**, and **Queue Workers** ready for deployment on Dokploy.

## 🚀 Features

- ✅ **Laravel 12** with PHP 8.2
- ✅ **Laravel Reverb** - Real-time WebSocket communication
- ✅ **Laravel Horizon** - Queue monitoring dashboard
- ✅ **Queue Workers** - Background job processing
- ✅ **External MySQL & MongoDB** support
- ✅ **Redis** for caching, sessions, and queues
- ✅ **Docker & Nixpacks** deployment options

## 📋 Quick Start

### 1. Set Your Domain
Edit `.env.nixpacks.production` and change:
```env
PRODUCTION_DOMAIN=your-domain.com
```
All other domain references will automatically update!

### 2. Set Database Connections
Replace these placeholders with your actual database details:
```env
# MySQL
DB_HOST=your-mysql-server.com
DB_DATABASE=your_database
DB_USERNAME=your_username
DB_PASSWORD=your_password

# MongoDB
MONGODB_HOST=your-mongodb-server.com
MONGODB_DATABASE=your_mongodb_db
MONGODB_USERNAME=your_mongo_user
MONGODB_PASSWORD=your_mongo_password
```

### 3. Deploy on Dokploy

#### Option A: Nixpacks (Recommended - Easier)
1. Create application in Dokploy
2. Choose **"Nixpacks"** build method
3. Copy all variables from `.env.nixpacks.production` to Dokploy environment variables
4. Deploy!

#### Option B: Docker Compose
1. Create Docker Compose application in Dokploy
2. Upload `docker-compose.production.yml`
3. Set environment variables in Dokploy (same as above)
4. Deploy!

## 🌐 Access Your Application

After deployment:
- **Main App**: `https://your-domain.com`
- **Horizon Dashboard**: `https://your-domain.com/horizon`
- **Health Check**: `https://your-domain.com/up`

## 🔑 Generated Keys (Already Set)

Your application comes with pre-generated secure keys:
- ✅ **APP_KEY**: `base64:d382dhqJQnQwKDdHshiAeWJPrXV5QrYjKt8nA+k7fUw=`
- ✅ **REVERB_APP_KEY**: `2zqXf/k6se11XifOcwsDtgBcVILKpW3I4rH8zPOeNaw=`
- ✅ **REVERB_APP_SECRET**: `eYl3aY/WfwP38wg6wzSKduxsOZqQx7pkemwD5qpYfgI=`
- ✅ **REDIS_PASSWORD**: `bBv4P99NGkd0ETb2L8lA2KKEgkZ8NB4TPnLRLZtxrYw=`

## 💡 What's Running

Your deployed application includes:
- **Nginx** - Web server
- **PHP-FPM** - Laravel application
- **Laravel Reverb** - WebSocket server (port 8080)
- **Laravel Horizon** - Queue management
- **Queue Workers** - 2 background workers
- **Task Scheduler** - Cron jobs
- **Redis** - Caching and queues

## 🧪 Test WebSocket Connection

```javascript
// In browser console
const ws = new WebSocket('wss://your-domain.com/app/your-reverb-key?protocol=7&client=js&version=8.4.0-rc2');
ws.onopen = () => console.log('WebSocket connected!');
```

## 🔧 Send Test Email Job

```php
// In Laravel Tinker or controller
App\Jobs\ProcessEmailQueue::dispatch('test@example.com', 'Test Subject', 'Hello World!');
```

## 📊 Monitor Your Application

- **Queue Status**: Visit `/horizon` to see queue workers and job processing
- **Application Logs**: Check Dokploy application logs
- **Health Check**: Visit `/up` to verify application status

## 🐛 Troubleshooting

### WebSocket Not Working?
- Check `REVERB_HOST` matches your domain exactly
- Ensure `REVERB_PORT=443` and `REVERB_SCHEME=https`

### Queue Jobs Not Processing?
- Visit `/horizon` to check worker status
- Verify Redis connection settings

### Database Connection Issues?
- Verify external database credentials
- Check if database accepts connections from Dokploy server IP

## 🔄 Local Development

```bash
# Start development environment
docker-compose up -d

# Access services
# App: http://localhost
# WebSocket: ws://localhost:6001
# Horizon: http://localhost/horizon
```

## 📁 File Structure

```
├── 🐳 Docker files
│   ├── Dockerfile
│   ├── docker-compose.yml (development)
│   └── docker-compose.production.yml (Dokploy)
├── 📦 Nixpacks
│   ├── nixpacks.toml
│   └── .env.nixpacks.production
├── 🎯 Laravel app
│   ├── app/Events/MessageSent.php (WebSocket example)
│   ├── app/Jobs/ProcessEmailQueue.php (Queue example)
│   └── config/reverb.php & horizon.php
└── 📚 This README.md
```

## 🎉 That's It!

Your Laravel application with WebSockets, Queue Management, and Background Workers is ready for production deployment on Dokploy!

**Need help?** Check the application logs in Dokploy or visit `/horizon` for queue monitoring.

---

**Built with ❤️ for Dokploy deployment**
