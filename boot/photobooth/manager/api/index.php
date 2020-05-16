<?php

include '../vendor/autoload.php';
include 'file.php';
include 'gpio.php';

use RestService\Server;
/* Exmaples:
 *
 * ->addGetRoute('foo/(.*)', function($bar)
 * ->addPostRoute('foo', function($field1, $field2)
 *
 */

Server::create('/')
	->addGetRoute('index.php', function(){
		return 'apiv1!';
	})

	// background
	->addGetRoute('background/get', function(){
		return FileAPI::get("background");
	})
	->addGetRoute('background/delete', function($fname){
		return FileAPI::delete("background", $fname);
	})
	->addPostRoute('background/store', function() {
		return FileAPI::store("background", $_FILES);
	})
	->addGetRoute('background/select', function($fname){
		return FileAPI::select("background", $fname);
	})

	// frame
	->addGetRoute('frame/get', function(){
		return FileAPI::get("frame");
	})
	->addGetRoute('frame/delete', function($fname){
		return FileAPI::delete("frame", $fname);
	})
	->addPostRoute('frame/store', function() {
		return FileAPI::store("frame", $_FILES);
	})
	->addGetRoute('frame/select', function($fname){
		return FileAPI::select("frame", $fname);
	})

	// gpio config
	->addPostRoute('gpio/store', function($actions) {
		return GpioAPI::store($actions);
	})
->run();
