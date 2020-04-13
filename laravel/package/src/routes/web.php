<?php

URL::forceRootUrl(Config::get('app.url'));
URL::forceScheme(explode(":", Config::get('app.url'))[0]);

Route::get('/', function () {
    return view('welcome');
});

#Route::post('/upload', 'RpiManager\Http\Controllers\DependencyUploadController@uploadFile')->middleware('web');
#Route::get('/upload', 'RpiManager\Http\Controllers\DependencyUploadController@testFile')->middleware('web');
