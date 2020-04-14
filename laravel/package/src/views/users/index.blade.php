@extends('rpimanager::layouts.app')

@section('content')

<div class="card mt-3">
    <div class="card-body">
        <h1><i class="fa fa-users"></i> User Administration <a href="{{ route('roles.index') }}" class="btn btn-default btn-primary pull-right ml-2">Roles</a>
        <a href="{{ route('permissions.index') }}" class="btn btn-default btn-primary pull-right ml-2">Permissions</a></h1>
        <div class="table-responsive">
            <table class="table table-sm table-bordered table-striped">

                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Country</th>
                        <th>API Token</th>
                        <th>Date Added</th>
                        <th>User Roles</th>
                        <th>Operations</th>
                    </tr>
                </thead>

                <tbody>
                    @foreach ($users as $user)
                    <tr>

                        <td>{{ $user->name }}</td>
                        <td>{{ $user->email }}</td>
                        <td>{!! isset($user->country) ? country($user->country)->getEmoji() : '' !!} {{ isset($user->country) ? '('. $user->country . ')' : '' }}</td>
                        <td style="font-size:10px;font-family:monospace" class="align-middle">{{ $user->api_token }}</td>
                        <td nowrap>{{ $user->created_at->format('m/d/y') }}</td>
                        <td nowrap>{{ $user->roles()->pluck('name')->implode(' ') }}</td>{{-- Retrieve array of roles associated to a user and convert to string --}}

                        <td>
                        <a href="{{ route('users.edit', $user->id) }}" class="btn btn-default btn-sm pull-left" style="margin-right: 3px;"><i class="fas fa-edit" aria-hidden="true"></i></a>

                        {!! Form::open(['method' => 'DELETE', 'route' => ['users.destroy', $user->id] ]) !!}
                        <!-- {!! Form::submit('Delete', ['class' => 'btn btn-danger']) !!} -->
                        {{ Form::button('<i class="fas fa-trash" aria-hidden="true"></i>', ['type' => 'submit', 'class' => 'btn btn-danger btn-sm'] )  }}
                        {!! Form::close() !!}

                        </td>
                    </tr>
                    @endforeach
                </tbody>

            </table>
        </div>

        <a href="{{ route('users.create') }}" class="btn btn-success">Add User</a>
    </div>
</div>
@endsection
