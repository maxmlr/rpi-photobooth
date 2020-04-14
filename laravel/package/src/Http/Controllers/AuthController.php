<?php

namespace App\Http\Controllers\Auth;

use App\User;
use App\Http\Controllers\Controller;
use Illuminate\Support\Str;
use Illuminate\Foundation\Auth\AuthenticatesUsers;
use Stevebauman\Location\Facades\Location;
use Laravel\Socialite\Facades\Socialite;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

use Request;
use Exception;

class AuthController extends Controller
{

    use AuthenticatesUsers;

    protected $redirectTo = '/';

    public function __construct()
    {
        $this->middleware('guest', ['except' => 'logout']);
    }

    public function createGoogleUser($user)
    {
        $authUser = User::where('google_id', $user->id)->first();
        if ($authUser) {
            return $authUser;
        } else {
            $mergeUser = User::where('email', $user->email)->first();
            if ($mergeUser) {
                $mergeUser->google_id = $user->id;
                $mergeUser->save();
                return $mergeUser;
            }
        }
        $newUser = User::create([
            'name' => $user->name,
            'email' => $user->email,
            'password' => Hash::make(Str::random(60))
        ]);
        $newUser->google_id = $user->id;
        if (is_object(Location::get(Request::ip()))) {
            $request_country = Location::get(Request::ip())->countryCode;
            $country_code = $request_country == "" ? "US" : $request_country;
        } else {
            $country_code = "US";
        }
        $newUser->country = $country_code;
        $newUser->api_token = Str::random(60);
        $newUser->save();
        return $newUser;
    }

    public function redirectToGoogle()
    {
        return Socialite::driver('google')->redirect();
    }

    public function handleGoogleCallback()
    {
        try {
            $user = Socialite::driver('google')->user();
            $authUser = $this->createGoogleUser($user);            
            Auth::login($authUser, true);
            return redirect()->route('home');
        } catch (Exception $e) {
            return redirect()->route('register');
        }
    }
}