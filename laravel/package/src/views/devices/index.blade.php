@extends('rpimanager::layouts.app')

@push('scripts')
<script>
    function interval(func, wait, times){
        var interv = function(w, t){
            return function(){
                if(typeof t === "undefined" || t-- > 0){
                    setTimeout(interv, w);
                    try{
                        func.call(null);
                    }
                    catch(e){
                        t = 0;
                        throw e.toString();
                    }
                }
            };
        }(wait, times);
        setTimeout(interv, wait);
    };
    function fetchdata(){
        $.ajax({
            url: "{{ route('devices.fetch') }}",
            type: 'get',
            dataType: 'json',
            success: function(response){
                response.forEach(function callback(device) {
                    pk = device['id']
                    row = $('.device-' + pk)

                    row_status = row.find('.fetch-status')
                    if ((row_status).text() != device['status']) {
                        row_status.fadeOut(250)
                    }
                    if(device['status'] !== null && device['status'] !== '') {
                        row_status.text(device['status']).fadeIn(250)
                    } else {
                        row_status.text('').fadeIn(250)
                    }

                    row_last_seen = row.find('.fetch-last_seen')
                    row_last_seen_info = row_last_seen.find('.last-seen-info')
                    row_last_seen_signal = row_last_seen.find('.last-seen-signal')
                    current_time = moment.utc()
                    last_seen_time = moment.utc(device['last_seen'], 'YYYY-MM-DD HH:mm:ss');
                    last_seen_time_table = moment.utc((row_last_seen_info).text(), 'MM/DD/YY HH:mm:ss Z')
                    if ((row_last_seen_info).text() != device['last_seen']) {
                        if ((row_last_seen_info).text() != '-' && !last_seen_time_table.isSame(last_seen_time)) {
                            row_last_seen_info.fadeOut(250)
                        }
                    }
                    if (device['last_seen'] === null || device['last_seen'] === '') {
                        row_last_seen_info.text('-').fadeIn(250)
                    } else {
                        last_seen_diff = current_time.diff(last_seen_time, 'seconds')
                        if (last_seen_diff < 60*2) {
                            row_last_seen_info.text(last_seen_diff + ' seconds ago').fadeIn(250)
                            row_last_seen_signal.css("color", "Dodgerblue")
                        } else {
                            row_last_seen_info.text(last_seen_time.format("MM/DD/YY HH:mm:ss Z")).fadeIn(250)
                            row_last_seen_signal.css("color", "lightgrey")
                        }
                    }

                    // fetch-control_request

                    row_control_http = row.find('.fetch-control_http')
                    if ((row_control_http).text() != device['control_http']) {
                        row_control_http.fadeOut(250)
                    }
                    if(device['control_http'] !== null && device['control_http'] !== '') {
                        row_control_http.html('<a href="' + device['control_http'] + '">' + device['control_http'] + '</a>').fadeIn(250)
                    } else {
                        row_control_http.html('<a href="#"></a>').fadeIn(250)
                    }

                    row_control_ssh = row.find('.fetch-control_ssh')
                    if ((row_control_ssh).text() != device['control_ssh']) {
                        row_control_ssh.fadeOut(250)
                    }
                    if(device['control_ssh'] !== null && device['control_ssh'] !== '') {
                        row_control_ssh.text(device['control_ssh']).fadeIn(250)
                        if (device['control_request']) {
                            row.find('.controlStatus').removeClass('fas fa-spinner fa-spin').addClass('far fa-check-circle').css('color', 'Dodgerblue')
                            row.find('.controlToggle').removeClass('disabled')
                        }
                    } else {
                        row_control_ssh.text('').fadeIn(250)
                        if (!device['control_request']) {
                            row.find('.controlStatus').removeClass('fas fa-spinner fa-spin').addClass('far fa-check-circle').css('color', 'lightgrey')
                            row.find('.controlToggle').removeClass('disabled')
                        }
                    }
                });
            }
        });
    }

    $(function() {
        interval(fetchdata, 5000);

        $.fn.editable.defaults.mode = 'inline';            

        $('.xedit').editable({
            type: 'text',
            showbuttons: false,
            ajaxOptions: {
                type: 'patch',
                dataType: 'json'
            },
            success: function (response, newValue) {
                console.log('[edit] Updated', response)
            }
        })
        
        $('.controlToggle').click(function() {
            $this = $(this)
            $this.addClass('disabled')
            data = $this.data()
            data['value'] = data['value'] ? 0 : 1
            $.ajax({
                type: "patch",
                url: $this.data('url'),
                data: $this.data(),
                dataType: 'json',
                success: function (response, status, jqXHR) {
                    console.log('[control] Updated', response)
                    if (response) {
                        $this.data('value', data['value'])
                        $this.find('.controlToggleButton').toggleClass('fa-headset fa-unlink')
                        if (data['value']) {
                            $('.device-' + $this.data('pk')).find('.controlStatus').removeClass('far fa-check-circle').addClass('fas fa-spinner fa-spin').css('color', 'Dodgerblue')
                        } else {
                            $('.device-' + $this.data('pk')).find('.controlStatus').removeClass('far fa-check-circle').addClass('fas fa-spinner fa-spin').css('color', 'red')
                        }
                    } else {
                        $this.removeClass('disabled')
                    }
                    jqXHR.always(function() {
                        console.log('[control] Updated', response)
                    });
                }
            });
        });
    })
</script>
@endpush

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
                        <th>Description</th>
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
                    <tr class="device-{{ $device->id }}">
                        <td class="align-middle">{{ $device->id }}</td>
                        <td class="align-middle">{{ $device->device_id }}</td>
                        <td class="align-middle">{{ $device->model }}</td>
                        <td class="align-middle">{{ $device->type }}</td>
                        <td class="align-middle">
                            <a href="#" class="xedit" 
                                   data-pk="{{ $device->id }}"
                                   data-name="description"
                                   data-url="{{ route('devices.update', $device->id) }}">
		                    	   {{ $device->description }}</a>
                        </td>
                        <td class="align-middle fetch-status" align="center">{{ $device->status }}</td>
                        <td class="align-middle fetch-last_seen" nowrap>
                            @isset($device->last_seen)
                                @php
                                    $seconds_last = now()->diffInSeconds($device->last_seen);
                                @endphp
                                @if($seconds_last < 60*2)
                                    <span class="last-seen-info">{{ $seconds_last }} seconds ago</span>
                                    <i class="last-seen-signal fas fa-signal float-right ml-3" style="color: Dodgerblue"></i>
                                @else
                                    <span class="last-seen-info">{{ $device->last_seen->format('m/d/y H:i:s P') }}</span>
                                    <i class="last-seen-signal fas fa-signal float-right ml-3" style="color: lightgrey"></i>
                                @endif
                            @else
                                <span class="last-seen-info">-</span>
                            @endif
                        </td>
                        <td class="align-middle fetch-control_request" align="center">
                            @if($device->control_request == '0')
                                @if(empty($device->control_ssh))
                                    <i class="controlStatus far fa-check-circle ml-3" style="color: lightgrey"></i>
                                @else
                                    <i class="controlStatus fas fa-spinner fa-spin ml-3" style="color: red"></i>
                                @endif
                            @elseif($device->control_request == '1')
                                @if(empty($device->control_ssh))
                                    <i class="controlStatus fas fa-spinner fa-spin ml-3" style="color: Dodgerblue"></i>
                                @else
                                    <i class="controlStatus far fa-check-circle ml-3" style="color: Dodgerblue"></i>
                                @endif
                            @else
                                <i class="controlStatus far fa-times-circle ml-3" style="color: red"></i>
                            @endif
                        </td>
                        <td class="align-middle fetch-control_http"><a href="{{ $device->control_http ?? '#' }}">{{ $device->control_http ?? '' }}</a></td>
                        <td class="align-middle fetch-control_ssh">{{ $device->control_ssh ?? '' }}</td>
                        <td class="align-middle">
                            <a href="#" class="controlToggle btn btn-sm btn-primary" 
                                data-pk="{{ $device->id }}"
                                data-name="control_request"
                                data-value="{{ $device->control_request }}"
                                data-url="{{ route('devices.update', $device->id) }}">
                                <i class="controlToggleButton fas {{ $device->control_request == '0' ? 'fa-headset' : 'fa-unlink' }}"></i>
                            </a>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
