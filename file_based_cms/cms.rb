require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubi"

get "/" do
  erb :index
end