@extends('rpimanager::layouts.app')

@section('content')

<div class="card mt-3">
    <div class="card-body">
        <div class="">
            <h1><i class="fa fa-key"></i> Available Permissions

            <a href="{{ route('users.index') }}" class="btn btn-default btn-primary pull-right ml-2">Users</a>
            <a href="{{ route('roles.index') }}" class="btn btn-default btn-primary pull-right ml-2">Roles</a></h1>

            <div class="table-responsive">
                <table class="table table-bordered table-striped">

                    <thead>
                        <tr>
                            <th>Permissions</th>
                            <th>Operation</th>
                        </tr>
                    </thead>
                    <tbody>
                        @foreach ($permissions as $permission)
                        <tr>
                            <td>{{ $permission->name }}</td>
                            <td>
                            <a href="{{ URL::to('permissions/'.$permission->id.'/edit') }}" class="btn btn-default btn-sm pull-left" style="margin-right: 3px;"><i class="fas fa-edit" aria-hidden="true"></i></a>

                            {!! Form::open(['method' => 'DELETE', 'route' => ['permissions.destroy', $permission->id] ]) !!}
                            <!-- {!! Form::submit('Delete', ['class' => 'btn btn-danger']) !!} -->
                            {{ Form::button('<i class="fas fa-trash" aria-hidden="true"></i>', ['type' => 'submit', 'class' => 'btn btn-danger btn-sm'] )  }}
                            {!! Form::close() !!}

                            </td>
                        </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>

            <a href="{{ URL::to('permissions/create') }}" class="btn btn-success">Add Permission</a>

        </div>
    </div>
</div>
@endsection
