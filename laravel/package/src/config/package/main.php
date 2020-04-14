<?php

return [

    /*
    |--------------------------------------------------------------------------
    | User Defined Variables
    |--------------------------------------------------------------------------
    |
    | This is a set of variables that are made specific to this application
    | that are better placed here rather than in .env file.
    | Use config('your_key') to get the values.
    |
    */

    'timezone' => env('TIMEZONE', 'UTC'),
    'gtag' => env('GTAG', 'UA-xxxxxxxx-x'),
    'caffeine_route'  => env('CAFFEINE_ROUTE', 'genealabs/laravel-caffeine/drip'),
    'slack_webhook_url' => env('SLACK_WEBHOOK_URL', 'https://hooks.slack.com/services/'),

];
