require 'sinatra'
require 'slim'
require_relative 'modules/auth'
require_relative 'modules/profile'
require_relative 'modules/question'

enable :sessions

include Auth
include Profile
include Question

get '/' do
    questions = Question::get_all_questions(Auth::get_logged_in_user_id(session), nil)
    return slim :'index/index', locals:get_layout_locals().merge({'questions' => questions, 'error': ''})
end

post '/' do
    if !Auth::is_authenticated(session)
        return redirect('/')
    end

    title = params['title']
    description = params['description']

    if title.empty? || description.empty?
        questions = Question::get_all_questions(Auth::get_logged_in_user_id(session), nil)
        return slim :'index/index', locals:get_layout_locals().merge({'questions' => questions, 'error': 'Please fill in all the fields!'})
    end

    Question::post_question(Auth::get_logged_in_user_id(session), title, description, nil)

    return redirect('/')
end

get '/question/:question_id/?' do
    question_id = params["question_id"].to_i
    question = Question::get_question(question_id, Auth::get_logged_in_user_id(session), nil)
    if question == nil
        return "404 - Question not found"
    end

    return slim :'index/question', locals:get_layout_locals().merge({"question": question})
end

post '/question/:question_id/?' do
    if !Auth::is_authenticated(session)
        return slim :'index/question', locals:get_layout_locals().merge({"question": question, "error": "You need to be logged in to answer!"})
    end
    question_id = params["question_id"].to_i
    message = params["answer"]

    if message.empty?
        return slim :'index/question', locals:get_layout_locals().merge({"question": question, "error": "You can't post an empty answer!"})
    end

    question = Question::get_question(question_id, Auth::get_logged_in_user_id(session), nil)
    if question == nil
        return "404 - Question not found"
    end

    Question::post_answer(question_id, message, Auth::get_logged_in_user_id(session), nil)

    return redirect("/question/#{question_id}/")
end

post '/like_question/?' do
    db = Auth::open_connection();
    account_id = params[:account_id]
    question_id = params[:question_id]
    Question::toggle_question_like(account_id, question_id, db)
    return Question::get_question_likes(question_id, db).size().to_s
end

post '/like_answer/?' do
    db = Auth::open_connection();
    account_id = params[:account_id]
    answer_id = params[:answer_id]
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
    login_name = params['login_name']
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
    email = params['email']
    username = params['username']
    password = params['password']
    password_confirm = params['password_confirm']

    if password != password_confirm
        return slim :'account/register', locals:get_layout_locals().merge({"error": "The passwords don't match!"})
    end

    account = Auth::register(email, username, password, session)
    if account == nil
        return slim :'account/register', locals:get_layout_locals().merge({"error": "Failed to create account!"})
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