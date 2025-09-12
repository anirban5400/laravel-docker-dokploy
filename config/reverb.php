<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default Reverb Server
    |--------------------------------------------------------------------------
    |
    | This option controls the default server used by Reverb to handle
    | WebSocket connections. This server is used when no server is
    | explicitly specified when broadcasting events.
    |
    */

    'default' => env('REVERB_SERVER', 'reverb'),

    /*
    |--------------------------------------------------------------------------
    | Reverb Servers
    |--------------------------------------------------------------------------
    |
    | Here you may define all of the Reverb servers for your application as
    | well as their drivers. You may even define multiple servers for the
    | same driver to allow for better load balancing.
    |
    */

    'servers' => [

        'reverb' => [
            'host' => env('REVERB_SERVER_HOST', '0.0.0.0'),
            'port' => env('REVERB_SERVER_PORT', 8080),
            'hostname' => env('REVERB_HOST'),
            'options' => [
                'tls' => [],
            ],
            'max_request_size' => env('REVERB_MAX_REQUEST_SIZE', 10000),
            'scaling' => [
                'enabled' => env('REVERB_SCALING_ENABLED', false),
                'channel' => env('REVERB_SCALING_CHANNEL', 'reverb'),
                'server' => [
                    'url' => env('REDIS_URL'),
                    'host' => env('REDIS_HOST', '127.0.0.1'),
                    'port' => env('REDIS_PORT', '6379'),
                    'username' => env('REDIS_USERNAME'),
                    'password' => env('REDIS_PASSWORD'),
                    'database' => env('REVERB_REDIS_DB', env('REDIS_DB', '0')),
                ],
            ],
            'pulse_ingest_interval' => env('REVERB_PULSE_INGEST_INTERVAL', 15),
            'telescope_ingest_interval' => env('REVERB_TELESCOPE_INGEST_INTERVAL', 15),
        ],

    ],

    /*
    |--------------------------------------------------------------------------
    | Reverb Applications
    |--------------------------------------------------------------------------
    |
    | Here you may define how Reverb applications are managed. A default
    | configuration has been defined for you. You are free to add more
    | applications as needed each with their own settings.
    |
    */

    'apps' => [

        'provider' => 'config',

        'apps' => [
            [
                'app_id' => env('REVERB_APP_ID', 'app'),
                'app_key' => env('REVERB_APP_KEY'),
                'app_secret' => env('REVERB_APP_SECRET'),
                'host' => env('REVERB_HOST'),
                'port' => env('REVERB_PORT', 443),
                'scheme' => env('REVERB_SCHEME', 'https'),
                'allowed_origins' => ['*'],
                'ping_interval' => env('REVERB_PING_INTERVAL', 30),
                'max_message_size' => env('REVERB_MAX_MESSAGE_SIZE', 10000),
            ],
        ],

    ],

];
