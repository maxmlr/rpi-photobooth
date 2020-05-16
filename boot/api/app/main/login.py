from flask import request, redirect, url_for, render_template
from flask_login import UserMixin, login_user, logout_user, current_user, login_required
from . import setup
from .. import ADMIN_USER, ADMIN_PASSWORD, login_manager

# users
users = {ADMIN_USER: {'password': ADMIN_PASSWORD}}
class User(UserMixin):
    pass

@login_manager.user_loader
def user_loader(email):
    if email not in users:
        return
    user = User()
    user.id = email
    return user

@login_manager.request_loader
def request_loader(request):
    email = request.form.get('email')
    if email not in users:
        return
    user = User()
    user.id = email
    if request.form['password'] == users[email]['password']:
        return user
    else:
        return None

@setup.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'GET':
        if current_user.is_authenticated:
            return redirect(url_for('setup.home'))
        return render_template('login.html')
    email = request.form['email']
    if email not in users:
        return render_template('login.html', **{ 'errors': "Email is not associated with a user." })
    if request.form['password'] == users[email]['password']:
        user = User()
        user.id = email
        login_user(user)
        return redirect(url_for('setup.home'))

    return render_template('login.html', **{ 'errors': "Wrong password." })

@setup.route('/logout')
def logout():
    logout_user()
    return render_template('login.html')

@login_manager.unauthorized_handler
def unauthorized_handler():
    return redirect(url_for('setup.login'))
