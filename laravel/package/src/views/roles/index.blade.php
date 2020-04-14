@extends('rpimanager::layouts.app')

@section('content')

<div class="card mt-3">
    <div class="card-body">
        <div class="">
            <h1><i class="fas fa-user-circle"></i> Roles

            <a href="{{ route('users.index') }}" class="btn btn-default btn-primary pull-right ml-2">Users</a>
            <a href="{{ route('permissions.index') }}" class="btn btn-default btn-primary pull-right ml-2">Permissions</a></h1>

            <div class="table-responsive">
                <table class="table table-bordered table-striped">
                    <thead>
                        <tr>
                            <th>Role</th>
                            <th>Permissions</th>
                            <th>Operation</th>
                        </tr>
                    </thead>

                    <tbody>
                        @foreach ($roles as $role)
                        <tr>

                            <td>{{ $role->name }}</td>

                            <td>{{  $role->permissions()->pluck('name')->implode(' ') }}</td>{{-- Retrieve array of permissions associated to a role and convert to string --}}
                            <td>
                            <a href="{{ URL::to('roles/'.$role->id.'/edit') }}" class="btn btn-default btn-sm pull-left" style="margin-right: 3px;"><i class="fas fa-edit" aria-hidden="true"></i></a>

                            {!! Form::open(['method' => 'DELETE', 'route' => ['roles.destroy', $role->id] ]) !!}
                            <!-- {!! Form::submit('Delete', ['class' => 'btn btn-danger']) !!} -->
                            {{ Form::button('<i class="fas fa-trash" aria-hidden="true"></i>', ['type' => 'submit', 'class' => 'btn btn-danger btn-sm'] )  }}
                            {!! Form::close() !!}

                            </td>
                        </tr>
                        @endforeach
                    </tbody>

                </table>
            </div>

            <a href="{{ URL::to('roles/create') }}" class="btn btn-success">Add Role</a>

        </div>
    </div>
</div>

@endsection
