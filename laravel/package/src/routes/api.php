<?php

use Illuminate\Http\Request;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::middleware('auth:api')->prefix('api')->group(function () {
    Route::get('v1/ping', 'RpiManager\Http\Controllers\ApiController@ping');
    Route::post('v1/device/register', 'RpiManager\Http\Controllers\DeviceController@store');
});

Route::middleware('api')->prefix('api')->group(function () {
    Route::get('v1/device/ping', function () {
        return response()->json([
            'message' => 'pong'
        ]);
    });
});

Route::middleware('auth:rpi')->prefix('api')->group(function () {
    Route::post('v1/device/report', 'RpiManager\Http\Controllers\DeviceController@report');
    Route::post('v1/device/control/status', 'RpiManager\Http\Controllers\DeviceController@control_status');
    Route::post('v1/device/control/callback', 'RpiManager\Http\Controllers\DeviceController@control_callback');
});
