@extends('rpimanager::layouts.app')

@section('content')

<div class="card mt-3">
    <div class="card-body">
        <div class="">

            <h1><i class='fas fa-user-circle'></i> Add Role</h1>
            <hr>
            {{-- @include ('errors.list') --}}

            {{ Form::open(array('url' => 'roles')) }}

            <div class="form-group">
                {{ Form::label('name', 'Name') }}
                {{ Form::text('name', null, array('class' => 'form-control')) }}
            </div>

            <h5><b>Assign Permissions</b></h5>

            <div class='form-group'>
                @foreach ($permissions as $permission)
                    {{ Form::checkbox('permissions[]',  $permission->id ) }}
                    {{ Form::label($permission->name, ucfirst($permission->name)) }}<br>

                @endforeach
            </div>

            {{ Form::submit('Add', array('class' => 'btn btn-primary')) }}

            {{ Form::close() }}

        </div>
    </div>
</div>

@endsection
