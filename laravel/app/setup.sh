#!/bin/sh

# --------------- setup laravel ---------------

cd /var/www/laravel
composer create-project laravel/laravel /var/www/laravel 7
cp /var/www/install/laravel.env /var/www/laravel/.env
composer config repositories.rpi-photobooth-manager path /var/www/package
composer require maxmlr/rpi-photobooth-manager:dev-master

# install RpiManager
echo "Installing RpiManager package..."

echo "Initialize laravel/ui auth..."
# install laravel auth
php artisan ui bootstrap --auth

# build frontend dependencies
npm install
npm run dev

echo "Publishing RpiManager package..."
# publish RpiManager
php artisan vendor:publish --provider="RpiManager\RpiManagerServiceProvider" --force --tag config --tag auth --tag migrations --tag seeds --tag kernels --tag assets

echo "Installing and publishing required packages..."
# publish debugbar
php artisan vendor:publish --provider="Barryvdh\Debugbar\ServiceProvider"
sed -i "s/'except' => \[/'except' => \[\n\t'api\/*',/" ./config/debugbar.php    # add api urls to exceptions

# publish spatie/permissions
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider" --tag config
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider" --tag migrations

# publishs genealabs\laravel-caffeine
php artisan vendor:publish --provider="GeneaLabs\LaravelCaffeine\Providers\Service" --tag config

# publishsStevebauman/location
php artisan vendor:publish --provider="Stevebauman\Location\LocationServiceProvider"

# publish email templates
php artisan vendor:publish --tag=laravel-notifications

# publish dougsisk\countrystate
php artisan vendor:publish --provider="DougSisk\CountryState\CountryStateServiceProvider" --tag config

echo "Running composer dump-autoload..."
composer dump-autoload

echo "Running database migrations..."
php artisan migrate

echo "Running database seeds..."
php artisan db:seed --class RpiManagerSeeder

# --------------- initializing folders ---------------
echo "Initializing folders"
#php artisan storage:link
cd /var/www/laravel/public
ln -s ../storage/app/public/ storage
cd /var/www/laravel

# --------------- js libraries ---------------
echo "Updating javascript and css libraries..."
/var/www/install/update_libs.sh

echo "Initializing..."
# php artisan optimize
php artisan key:generate

# --------------- setup end ---------------
echo "Installation successful."
cd - > /dev/null
