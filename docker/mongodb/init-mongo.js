// MongoDB initialization script
// This script runs when the MongoDB container starts for the first time

// Switch to the Laravel database
db = db.getSiblingDB('laravel_mongodb');

// Create a user for Laravel application
db.createUser({
  user: 'laravel_user',
  pwd: 'laravel_password',
  roles: [
    {
      role: 'readWrite',
      db: 'laravel_mongodb'
    }
  ]
});

// Create some initial collections with indexes
db.createCollection('users');
db.createCollection('sessions');
db.createCollection('cache');
db.createCollection('jobs');
db.createCollection('failed_jobs');

// Create indexes for better performance
db.users.createIndex({ "email": 1 }, { unique: true });
db.sessions.createIndex({ "last_activity": 1 });
db.cache.createIndex({ "expiration": 1 }, { expireAfterSeconds: 0 });
db.jobs.createIndex({ "queue": 1, "reserved_at": 1 });

print('MongoDB initialized for Laravel application');
