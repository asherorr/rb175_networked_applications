require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubi"

get "/" do
  @files = Dir.glob("data/*").map { |path| File.basename(path) }
  erb :index
end

