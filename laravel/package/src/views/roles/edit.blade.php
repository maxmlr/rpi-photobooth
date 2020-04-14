@extends('rpimanager::layouts.app')

@section('content')

<div class="card mt-3">
    <div class="card-body">
        <div class="">
            <h1><i class='fas fa-user-circle'></i> Edit Role: {{$role->name}}</h1>
            <hr>
            {{-- @include ('errors.list')
         --}}
            {{ Form::model($role, array('route' => array('roles.update', $role->id), 'method' => 'PUT')) }}

            <div class="form-group">
                {{ Form::label('name', 'Role Name') }}
                {{ Form::text('name', null, array('class' => 'form-control')) }}
            </div>

            <h5><b>Assign Permissions</b></h5>
            @foreach ($permissions as $permission)

                {{Form::checkbox('permissions[]',  $permission->id, $role->permissions ) }}
                {{Form::label($permission->name, ucfirst($permission->name)) }}<br>

            @endforeach
            <br>
            {{ Form::submit('Edit', array('class' => 'btn btn-primary')) }}

            {{ Form::close() }}
        </div>
    </div>
</div>

@endsection
