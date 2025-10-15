require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubi"
require "securerandom"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :data_path, File.expand_path("../data", __dir__)
end

configure :test do
  # When RACK_ENV=test, use test fixtures
  set :data_path, File.expand_path("../test/data", __dir__)
end

helpers do
  def display_flash
    return unless session[:error]
    %(<div class="flash error"><h1>#{session.delete(:error)}</h1></div>)
  end
end

def get_all_files
  Dir.glob(File.join(settings.data_path, "*")).map { |path| File.basename(path) }
end

get "/" do
  @files = get_all_files
  erb :index
end

get "/data/:file" do
  file_name = params[:file]
  file_path = File.join(settings.data_path, file_name)

  @contents = File.read(file_path)
  erb :file
  rescue Errno::ENOENT
    session[:error] = "The file '#{file_name}' doesn't exist."
    redirect "/"
end