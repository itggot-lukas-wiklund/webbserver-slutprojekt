require 'sinatra'
require 'slim'
require_relative 'modules/auth'

include Auth

get '/' do
    return slim(:index, locals:get_layout_locals())
end

def get_layout_locals()
    return {'is_authenticated' => Auth::is_authenticated(session)}
end