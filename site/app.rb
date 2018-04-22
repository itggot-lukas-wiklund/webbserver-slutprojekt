require 'sinatra'
require 'slim'
require_relative 'modules/auth'
require_relative 'modules/profile'

enable :sessions

include Auth
include Profile

get '/' do
    return slim :'index/index', locals:get_layout_locals()
end

# ----- Profile -----
get '/profile/?' do
    if !Auth::is_authenticated(session)
        return redirect('/')
    end

    profile = Profile::get_profile(get_logged_in_user_id(session), nil)
    return slim :'profile/my_profile', locals:get_layout_locals().merge({'profile' => profile})
end

# ----- Account -----
get '/account/login/?' do
    return slim :'account/login', locals:get_layout_locals()
end

post '/account/login/?' do
    login_name = params['login_name']
    password = params['password']

    account = Auth::login(login_name, password, session)
    if account == nil
        return slim :'account/login', locals:get_layout_locals()
    end

    return redirect('/')
end

get '/account/register/?' do
    return slim :'account/register', locals:get_layout_locals()
end

post '/account/register/?' do
    email = params['email']
    username = params['username']
    password = params['password']
    password_confirm = params['password_confirm']

    if password != password_confirm
        return slim :'account/register', locals:get_layout_locals()
    end

    account = Auth::register(email, username, password, session)
    if account == nil
        return slim :'account/register', locals:get_layout_locals()
    end

    return redirect('/account/setup_profile/')
end

get '/account/logout/?' do
    Auth::logout(session)
    return redirect('/')
end

get '/account/setup_profile/?' do
    if Auth::is_authenticated(session)
        genders = Profile::get_genders()
        return slim :'account/setup_profile', locals:get_layout_locals().merge({'genders' => genders})
    end

    return redirect('/account/login/')
end

post '/account/setup_profile/?' do
    account_id = Auth::get_logged_in_user_id(session)
    if account_id == nil
        genders = Profile::get_genders()
        return slim :'account/setup_profile', locals:get_layout_locals().merge({'genders' => genders})
    end

    name = params['name']
    gender_id = params['gender']
    location = params['location']

    Profile::update_profile(account_id, name, gender_id, location)

    return redirect('/')
end

get '/account/settings/?' do
    if Auth::is_authenticated(session)
        return slim :'account/settings', locals:get_layout_locals()
    end

    return redirect('/account/login/')
end

post '/account/settings/?' do

end

def get_layout_locals()
    return {
        'is_authenticated' => Auth::is_authenticated(session),
        'user' => Auth::get_logged_in_user(session)
    }
end