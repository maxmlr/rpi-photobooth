#!/usr/bin/env bash

set -e

role=${CONTAINER_ROLE:-app}
env=${APP_ENV:-production}

if [ "$env" != "local" ]; then
    echo "Caching configuration..."
    (cd /var/www/laravel && php artisan config:cache && php artisan route:cache && php artisan view:cache)
fi

if [ "$role" = "app" ]; then

    exec docker-php-entrypoint php-fpm

elif [ "$role" = "queue" ]; then

    echo "Running the queue..."
    /usr/local/bin/wait-for ${REDIS_HOST}:${REDIS_PORT} -- php /var/www/laravel/artisan queue:work $WORKER_CONNECTION --daemon --verbose --queue=$WORKER_QUEUE --timeout=90

elif [ "$role" = "scheduler" ]; then
    /usr/local/bin/wait-for ${REDIS_HOST}:${REDIS_PORT}
    while [ true ]
    do
      php /var/www/laravel/artisan schedule:run --verbose --no-interaction &
      sleep 60
    done

else
    echo "Could not match the container role \"$role\""
    exit 1
fi
