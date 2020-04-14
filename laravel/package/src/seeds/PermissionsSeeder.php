<?php

use App\User;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use Illuminate\Database\Seeder;

class PermissionsSeeder extends Seeder {
    public function run()
    {
        Role::truncate();
        Role::create([
            'name' => 'super-admin',
            'guard_name' => 'web'
            ]);
        Role::create([
            'name' => 'manager',
            'guard_name' => 'web'
            ]);

        Permission::truncate();
        $permission = new Permission();
        $permission->name = 'Administer roles & permissions';
        $permission->guard_name = 'web';
        $permission->save();
        $role = Role::where('name', '=', 'super-admin')->firstOrFail();
        $role->givePermissionTo($permission);
        $user = User::where('name', '=', env('ADMIN_NAME', 'Administrator'))->firstOrFail();
        $user->assignRole($role);
    }
}
