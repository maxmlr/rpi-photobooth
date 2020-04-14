<?php

namespace RpiManager\Http\Controllers;

use App\Http\Controllers\Controller;
use RpiManager\Device;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class DeviceController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        return view('rpimanager::devices.index')->with('devices', Device::all());
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        $this->validate($request, [
            'device_id'=>'required|string|unique:devices',
            'model'=>'required|string|max:120',
            'type'=>'required|string|max:120'
        ]);

        $device = Device::create($request->only('device_id', 'model', 'type'));
        $device->api_token = Str::random(60);
        $device->status = 'registered';
        $device->last_seen = now();
        $device->save();
        return response()->json([
            'api_token' => $device->api_token
        ]);
    }

    /**
     * Display the specified resource.
     *
     * @param  \App\Device  $device
     * @return \Illuminate\Http\Response
     */
    public function show(Device $device)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \App\Device  $device
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, Device $device)
    {
        $this->validate($request, [
            'device_id'=>'required|string|exists:devices',
            'status'=>'string|max:20|nullable',
            'payload'=>'string|nullable',
        ]);

        $device = Device::firstWhere('device_id', $request->device_id);
        $device->status = $request->status;
        $device->last_seen = now();
        $device->save();

        return response()->json([
            'message' => 'success'
        ]);
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  \App\Device  $device
     * @return \Illuminate\Http\Response
     */
    public function destroy(Device $device)
    {
        //
    }

    /**
     * Check Device control request status.
     *
     * @param  \App\Device  $device
     * @return \Illuminate\Http\Response
     */
    public function control_status(Request $request, Device $device)
    {

        $this->validate($request, [
            'device_id'=>'required|string|exists:devices'
        ]);

        $device = Device::firstWhere('device_id', $request->device_id);

        return response()->json([
            'message' => $device->control_request
        ]);
    }

    /**
     * Device control request callback.
     *
     * @param  \App\Device  $device
     * @return \Illuminate\Http\Response
     */
    public function control_callback(Request $request, Device $device)
    {

        $this->validate($request, [
            'device_id'=>'required|string|exists:devices',
            'status'=>'required|string|max:120',
            'tunnels'=>'required'
        ]);

        $device = Device::firstWhere('device_id', $request->device_id);
        $tunnels = json_decode($request->tunnels);
        if ($request->status == 'up') {
            $tcp = explode(":", $tunnels->tcp);
            $ssh_host = substr($tcp[1], 2);
            $ssh_port = $tcp[2];
            $device->control_ssh = "ssh -p{$ssh_port} root@{$ssh_host}";
            $device->control_http = $tunnels->http;
        } elseif ($request->status == 'down') {
            $device->control_ssh = NULL;
            $device->control_http = NULL;
        } elseif ($request->status == 'error') {
            $device->control_request = -1;
            $device->control_ssh = NULL;
            $device->control_http = NULL;
        }
        $device->save();

        return response()->json([
            'message' => 'success'
        ]);
    }

}
