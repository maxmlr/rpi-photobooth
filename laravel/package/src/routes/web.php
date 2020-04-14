<?php

URL::forceRootUrl(Config::get('app.url'));
URL::forceScheme(explode(":", Config::get('app.url'))[0]);

// Landing
Route::get('/', function () {
    return view('rpimanager::welcome');
});

// Google Auth
// Route::get('auth/google', 'App\Http\Controllers\Auth\AuthController@redirectToGoogle')->middleware('web');
// Route::get('auth/google/callback', 'App\Http\Controllers\Auth\AuthController@handleGoogleCallback')->middleware('web');

// Management Routes
Route::resource('users', 'RpiManager\Http\Controllers\UserController')->middleware(['web','auth']);
Route::resource('roles', 'RpiManager\Http\Controllers\RoleController')->middleware(['web','auth']);
Route::resource('permissions', 'RpiManager\Http\Controllers\PermissionController')->middleware(['web','auth']);

// Devices
Route::resource('devices', 'RpiManager\Http\Controllers\DeviceController')->middleware(['web','auth']);

#Route::post('/upload', 'RpiManager\Http\Controllers\DependencyUploadController@uploadFile')->middleware('web');
#Route::get('/upload', 'RpiManager\Http\Controllers\DependencyUploadController@testFile')->middleware('web');
