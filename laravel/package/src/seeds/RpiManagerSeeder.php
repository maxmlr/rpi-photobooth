<?php

use Illuminate\Database\Seeder;

class RpiManagerSeeder extends Seeder
{
    /**
     * Run the database seeds.
     *
     * @return void
     */
    public function run()
    {
        Eloquent::unguard();

		// disable foreign key check
		DB::statement('SET FOREIGN_KEY_CHECKS=0;');
			
		$this->call(UsersTableSeeder::class);
        $this->call(PermissionsSeeder::class);

		// enable foreign key check
		DB::statement('SET FOREIGN_KEY_CHECKS=1;');   
    }
}
