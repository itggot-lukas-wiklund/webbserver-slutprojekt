require 'sinatra'
require 'slim'

get '/' do
    return slim(:index, locals:get_layout_locals())
end

def get_layout_locals()
    return {'is_authenticated' => false}
end