require 'sinatra'
require 'slim'
require_relative 'modules/auth'
require_relative 'modules/profile'
require_relative 'modules/question'
require_relative 'modules/escaper'

enable :sessions

include Auth
include Profile
include Question
include Escaper

get '/' do
    questions = Question::get_all_questions(Auth::get_logged_in_user_id(session), nil)
    return slim :'index/index', locals:get_layout_locals().merge({'questions' => questions, 'error': ''})
end

post '/' do
    if !Auth::is_authenticated(session)
        return redirect('/')
    end

    title = Escaper::escape(params['title'])
    description = Escaper::escape(params['description'])

    if title.empty? || description.empty?
        questions = Question::get_all_questions(Auth::get_logged_in_user_id(session), nil)
        return slim :'index/index', locals:get_layout_locals().merge({'questions' => questions, 'error': 'Please fill in all the fields!'})
    end

    Question::post_question(Auth::get_logged_in_user_id(session), title, description, nil)

    return redirect('/')
end

get '/question/:question_id/?' do
    question_id = Escaper::escape(params["question_id"]).to_i
    question = Question::get_question(question_id, Auth::get_logged_in_user_id(session), nil)
    if question == nil
        return "404 - Question not found"
    end

    return slim :'index/question', locals:get_layout_locals().merge({"question": question, "error": ""})
end

post '/question/:question_id/?' do
    if !Auth::is_authenticated(session)
        return slim :'index/question', locals:get_layout_locals().merge({"question": question, "error": "You need to be logged in to answer!"})
    end
    question_id = Escaper::escape(params["question_id"]).to_i
    message = Escaper::escape(params["answer"])

    question = Question::get_question(question_id, Auth::get_logged_in_user_id(session), nil)
    if question == nil
        return "404 - Question not found"
    end

    if message.empty?
        return slim :'index/question', locals:get_layout_locals().merge({"question": question, "error": "You can't post an empty answer!"})
    end

    Question::post_answer(question_id, message, Auth::get_logged_in_user_id(session), nil)

    return redirect("/question/#{question_id}/")
end

post '/like_question/?' do
    db = Auth::open_connection();
    account_id = Escaper::escape(params[:account_id]).to_i
    question_id = Escaper::escape(params[:question_id]).to_i
    Question::toggle_question_like(account_id, question_id, db)
    return Question::get_question_likes(question_id, db).size().to_s
end

post '/like_answer/?' do
    db = Auth::open_connection();
    account_id = Escaper::escape(params[:account_id]).to_i
    answer_id = Escaper::escape(params[:answer_id]).to_i
    Question::toggle_answer_like(account_id, answer_id, db)
    return Question::get_answer_likes(answer_id, db).size().to_s
end

# ----- Profile -----
get '/profile/?' do
    if !Auth::is_authenticated(session)
        return redirect('/')
    end

    profile = Profile::get_profile(get_logged_in_user_id(session), nil)
    if profile["name"].empty?
        return redirect("/account/setup_profile/")
    end

    return slim :'profile/my_profile', locals:get_layout_locals().merge({'profile' => profile})
end

post '/profile/change_avatar/?' do
    if !Auth::is_authenticated(session)
        return redirect('/')
    end

    file = params["file"]
    if file == nil
        return redirect("/profile/")
    end

    filename = file["filename"]
    tempfile = file["tempfile"]

    while File.exists?(File.join(Dir.pwd, "/public/uploads/avatars/", filename))
        index = filename.length - 1
        dot_index = 0
        while index > 0
            char = filename[index]
            if char == "."
                dot_index = index
                break
            end
            index -= 1
        end
        basename = filename[0..dot_index - 1]
        extension = ""
        if dot_index != 0
            extension = filename[dot_index + 1..filename.length - 1]
        end
        basename += "0"
        filename = basename + "." + extension
    end

    File.open(File.join(Dir.pwd, "/public/uploads/avatars/", filename), 'wb') do |f|
        f.write(tempfile.read)
    end

    Profile::update_profile_avatar(Auth::get_logged_in_user_id(session), filename, nil)

    return redirect("/profile/")
end

# ----- Account -----
get '/account/login/?' do
    return slim :'account/login', locals:get_layout_locals().merge({"error": ""})
end

post '/account/login/?' do
    login_name = Escaper::escape(params['login_name'])
    password = params['password']

    account = Auth::login(login_name, password, session)
    if account == nil
        return slim :'account/login', locals:get_layout_locals().merge({"error": "Wrong login credentials!"})
    end

    return redirect('/')
end

get '/account/register/?' do
    return slim :'account/register', locals:get_layout_locals().merge({"error": ""})
end

post '/account/register/?' do
    email = Escaper::escape(params['email'])
    username = Escaper::escape(params['username'])
    password = params['password']
    password_confirm = params['password_confirm']

    if password != password_confirm
        return slim :'account/register', locals:get_layout_locals().merge({"error": "The passwords don't match!"})
    end

    account = Auth::register(email, username, password, session)
    if account == 1
        return slim :'account/register', locals:get_layout_locals().merge({"error": "Email is already in use!"})
    elsif account == 2
        return slim :'account/register', locals:get_layout_locals().merge({"error": "Username is already in use!"})
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
        return redirect("/account/login/")
    end

    name = Escaper::escape(params['name'])
    gender_id = Escaper::escape(params['gender']).to_i
    location = Escaper::escape(params['location'])

    Profile::update_profile(account_id, name, gender_id, location)

    return redirect('/')
end

get '/account/settings/?' do
    if Auth::is_authenticated(session)
        return slim :'account/settings', locals:get_layout_locals().merge({"change_password_error": "", "change_password_message": ""})
    end

    return redirect('/account/login/')
end

post '/account/settings/change_password/?' do
    if !Auth::is_authenticated(session)
        return redirect("/account/login/")
    end
    old_password = params['old_password']
    new_password = params['new_password']
    new_password_confirm = params['new_password_confirm']

    if old_password.empty? || new_password.empty? || new_password_confirm.empty?
        return slim :'account/settings', locals:get_layout_locals().merge({"change_password_error": "Please fill in all the fields!", "change_password_message": ""})
    end

    if new_password != new_password_confirm
        return slim :'account/settings', locals:get_layout_locals().merge({"change_password_error": "New passwords don't match!", "change_password_message": ""})
    end

    if old_password == new_password
        return slim :'account/settings', locals:get_layout_locals().merge({"change_password_error": "The old and the new password have to be different!", "change_password_message": ""})
    end

    result = Auth::change_password(Auth::get_logged_in_user_id(session), old_password, new_password, nil)

    if result == 0
        return slim :'account/settings', locals:get_layout_locals().merge({"change_password_error": "", "change_password_message": "Password changed successfully!"})
    elsif result == 1
        return slim :'account/settings', locals:get_layout_locals().merge({"change_password_error": "User not found!", "change_password_message": ""})
    elsif result == 2
        return slim :'account/settings', locals:get_layout_locals().merge({"change_password_error": "Wrong old password!", "change_password_message": ""})
    end
end

def get_layout_locals()
    return {
        'is_authenticated' => Auth::is_authenticated(session),
        'user' => Auth::get_logged_in_user(session)
    }
end