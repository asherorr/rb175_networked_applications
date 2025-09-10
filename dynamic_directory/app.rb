require "sinatra"
require "sinatra/reloader"
require "tilt/erubi"

get "/" do
  @list_of_files = Dir.glob("public/*").map { |path| File.basename(path) }
  @list_of_files.reverse! if params[:sort] == "desc"
  erb :home
end
