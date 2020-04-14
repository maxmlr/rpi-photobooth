<?php

use App\User;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UsersTableSeeder extends Seeder {
    public function run()
    {
        User::truncate();
        User::create([
            'name' => env('ADMIN_NAME', 'Administrator'),
            'email' => env('ADMIN_EMAIL', 'admin@app.local'),
            'password' => Hash::make(env('ADMIN_PASSWORD', 'adminPasswd')),
            'api_token' => Str::random(60)
        ])->save();
        User::create([
            'name' => env('DEVICE_MANAGER_NAME', 'DeviceManager'),
            'email' => env('DEVICE_MANAGER_EMAIL', 'manager@app.local'),
            'password' => Hash::make(env('DEVICE_MANAGER_PASSWORD', 'managerPasswd')),
            'api_token' => env('DEVICE_MANAGER_TOKEN', Str::random(60))
        ])->save();
    }
}
