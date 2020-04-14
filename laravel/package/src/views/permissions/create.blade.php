@extends('rpimanager::layouts.app')

@section('content')

<div class="card mt-3">
    <div class="card-body">
        <div class="">

            {{-- @include ('errors.list') --}}

            <h1><i class='fa fa-key'></i> Add Permission</h1>
            <br>

            {{ Form::open(array('url' => 'permissions')) }}

            <div class="form-group">
                {{ Form::label('name', 'Name') }}
                {{ Form::text('name', '', array('class' => 'form-control')) }}
            </div>
            <br>

            @if(!$roles->isEmpty())

                <h4>Assign Permission to Roles</h4>

                @foreach ($roles as $role)
                    {{ Form::checkbox('roles[]',  $role->id ) }}
                    {{ Form::label($role->name, ucfirst($role->name)) }}<br>

                @endforeach

            @endif

            <br>
            {{ Form::submit('Add', array('class' => 'btn btn-primary')) }}

            {{ Form::close() }}

        </div>
    </div>
</div>

@endsection
