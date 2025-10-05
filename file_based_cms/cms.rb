require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubi"

get "/" do
  @files = Dir.glob("data/*").map { |path| File.basename(path) }
  erb :index
end

#make a route for each file in the data folder
#build a route with params to capture the file
#show the contents of the page

get "/data/:file" do
  file_name = params[:file]

  @contents = File.read("data/#{file_name}")
  erb :file
end