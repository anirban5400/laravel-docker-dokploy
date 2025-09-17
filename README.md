# Laravel Docker (Dokploy-ready)

Simple, production-ready Docker setup for a Laravel app with services for app, queue worker, scheduler, reverb (WebSocket), and redis.

## Structure
```
docker/
  app/       Dockerfile, entrypoint.sh, wait-for-db.sh
  queue/     Dockerfile, entrypoint.sh
  scheduler/ Dockerfile, entrypoint.sh
  reverb/    Dockerfile, entrypoint.sh
  redis/     Dockerfile
docker-compose.yml
```

## Quick start
```bash
cp .env.example .env
php artisan key:generate

docker-compose build
docker-compose up -d
```

## Services (compose)
- app: Laravel PHP-FPM (serves on 8000)
- queue: runs `php artisan queue:work`
- scheduler: runs `php artisan schedule:work`
- reverb: runs `php artisan reverb:start` (8080 mapped if enabled)
- redis: cache/queue backend

## Configure
Edit `.env`:
- Database (external clusters): `DB_HOST`, `DB_PORT`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`
- Redis: `REDIS_HOST=redis`
- Reverb: `REVERB_APP_ID`, `REVERB_APP_KEY`, `REVERB_APP_SECRET`

## Common commands
```bash
docker-compose ps               # list services
docker-compose logs -f app      # app logs
docker-compose restart queue    # restart queue
docker-compose down             # stop all
```

## Notes
- MongoDB/MySQL services are optional and commented out in compose.
- Images use security updates and healthchecks; override as needed for your infra.
