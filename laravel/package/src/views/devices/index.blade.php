@extends('rpimanager::layouts.app')

@section('content')
<div class="card">
    <div class="card-body">
        <h1><i class="fas fa-network-wired"></i> Devices</h1>
        <div class="table-responsive">
            <table class="table table-sm table-bordered table-striped">
                <thead>
                    <tr>
                        <th>id</th>
                        <th>Device ID</th>
                        <th>Model</th>
                        <th>Type</th>
                        <th>Status</th>
                        <th>Last Seen</th>
                        <th>Control</th>
                        <th>Photobooth</th>
                        <th>Terminal</th>
                        <th>Controls</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach ($devices as $device)
                    <tr>
                        <td>{{ $device->id }}</td>
                        <td>{{ $device->device_id }}</td>
                        <td>{{ $device->model }}</td>
                        <td>{{ $device->type }}</td>
                        <td align="center">{{ $device->status }}</td>
                        <td nowrap>
                            @isset($device->last_seen)
                                @php
                                    $seconds_last = now()->diffInSeconds($device->last_seen);
                                @endphp
                                @if($seconds_last < 60*2)
                                    {{ $seconds_last }} seconds ago
                                    <i class="fas fa-signal ml-3" style="color: Dodgerblue"></i>
                                @else
                                    {{ $device->last_seen->format('m/d/y H:i:s') }} {{ config('main.timezone') }}
                                    <i class="fas fa-signal ml-3" style="color: lightgrey"></i>
                                @endif
                            @else
                                -
                            @endif
                        </td>
                        <td align="center">
                            @if($device->control_request == '0')
                                <i class="far fa-check-circle ml-3" style="color: lightgrey"></i>
                            @elseif($device->control_request == '1')
                                <i class="far fa-check-circle ml-3" style="color: Dodgerblue"></i>
                            @else
                                <i class="far fa-times-circle ml-3" style="color: red"></i>
                            @endif
                        </td>
                        <td><a href="{{ $device->control_http ?? '#' }}">{{ $device->control_http ?? '' }}</a></td>
                        <td>{{ $device->control_ssh ?? '' }}</td>
                        <td><i class="fas fa-headset"></i></td> <!-- <i class="far fa-window-close"></i> -->
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
