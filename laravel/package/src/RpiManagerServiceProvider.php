<?php

namespace RpiManager;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\View;
use Illuminate\Support\Facades\Schema;
use Illuminate\Console\Scheduling\Schedule;

class RpiManagerServiceProvider extends ServiceProvider
{
    /**
     * Bootstrap the application services.
     *
     * @return void
     */
    public function boot()
    {
        $this->app->booted(function () {
            Config::set('services.google', Config::get('rpimanager.services.google'));
            Config::set('genealabs-laravel-caffeine.route', Config::get('rpimanager.caffeine_route'));
            Config::set('app.timezone', Config::get('rpimanager.timezone'));
            date_default_timezone_set(Config::get('app.timezone'));
            $this->loadRoutesFrom(__DIR__.'/routes/web.php');
            $this->loadRoutesFrom(__DIR__.'/routes/api.php');
            $schedule = $this->app->make(Schedule::class);
            // $schedule->command(',,,')->name('...')->everyMinute()->withoutOverlapping();
        });

        $this->publishes([
            __DIR__ . '/views' => resource_path('views/vendor/rpi-photobooth-manager')
        ], 'views');

        $this->publishes([
            __DIR__ . '/migrations'  => database_path('/migrations')
        ], 'migrations');

        $this->publishes([
            __DIR__ . '/seeds'  => database_path('/seeds')
        ], 'seeds');

        $this->publishes([
            __DIR__ . '/config' => config_path('rpimanager')
        ], 'config');

        $this->publishes([
            __DIR__ . '/config/3rdparty' => config_path()
        ], '3rdparty');

        $this->publishes([
            __DIR__.'/models/User.php' => base_path('app/User.php'),
            __DIR__.'/Http/Controllers/Auth' => base_path('app/Http/Controllers/Auth')
        ], 'auth');

        $this->publishes([
            __DIR__.'/assets' => public_path('vendor/rpi-photobooth-manager'),
        ], 'assets');

        $this->publishes([
            __DIR__.'/Console/Kernel.php' => base_path('app/Console/Kernel.php'),
            __DIR__.'/Http/Kernel.php' => base_path('app/Http/Kernel.php'),
        ], 'kernels');

        $this->loadViewsFrom(
            __DIR__ . '/views', 'rpimanager'
        );

    }

    /**
     * Register the application services.
     *
     * @return void
     */
    public function register()
    {
        $this->mergeConfigFrom(
            __DIR__ . '/config/main.php', 'rpimanager'
        );

        $this->commands([
            //
        ]);
    }
}
