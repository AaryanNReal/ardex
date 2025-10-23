<?php
use Illuminate\Support\Facades\Route;

Route::get('/session-test', function () {
    session(['test' => 'BookStack session works!']);
    return 'Session stored: ' . session('test');
});
