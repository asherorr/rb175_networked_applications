require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubi"
require "securerandom"
require "redcarpet"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
  set :data_path, File.expand_path("data", __dir__)
end

configure :test do
  # When RACK_ENV=test, use test fixtures
  set :data_path, File.expand_path("../test/data", __dir__)
end

helpers do
  include Rack::Utils

  def display_flash
    [:error, :success, :info].each do |type|
      next unless session[type]

      message = session.delete(type)

      css_class = case type
                  when :error   then "flash error"
                  when :success then "flash success"
                  when :info    then "flash info"
                  else "flash"
                  end

      return %(<div class="#{css_class}"><h1>#{message}</h1></div>)
    end
    nil
  end

  def render_file(file_path)
    contents = File.read(file_path)
    if is_markdown_file?(file_path)
      renderer = Redcarpet::Render::HTML.new(hard_wrap: true)
      markdown = Redcarpet::Markdown.new(
        renderer,
        fenced_code_blocks: true,
        autolink: true,
        tables: true
      )
      markdown.render(contents)   # returns HTML
    else
      contents                    # plain text
    end
  end
end

def get_all_files
  Dir.glob(File.join(settings.data_path, "*")).map { |path| File.basename(path) }
end

def is_markdown_file?(file_name)
  file_name[-3..-1].downcase == ".md"
end

def has_valid_file_extension?(name)
  ext = File.extname(name.to_s).downcase
  [".txt", ".md"].include?(ext)
end

get "/" do
  @files = get_all_files
  erb :index
end

get "/data/:file" do
  file_name = params[:file]
  file_path = File.join(settings.data_path, file_name)
  @contents = render_file(file_path)

  content_type :html
  erb :file

  rescue Errno::ENOENT
    session[:error] = "The file '#{file_name}' doesn't exist."
    redirect "/"
end

get "/data/:file_name/edit" do
  @file_name = params[:file_name]
  file_path = File.join(settings.data_path, @file_name)
  @contents = render_file(file_path)
  erb :edit_file

  rescue Errno::ENOENT
    session[:error] = "The file '#{file_name}' doesn't exist."
    redirect "/"
end

post "/data/:file_name/edit_file" do
  file_path = File.join(settings.data_path, params[:file_name])
  
  File.write(file_path, params[:content])
  session[:success] = "#{params[:file_name]} has been updated."
  redirect "/"
end

get "/new_file" do
  content_type :html
  erb :new_file
end

post "/new_file" do
  filename = params[:file_name].to_s.strip

  if filename.empty?
    session[:error] = "A name is required."
    status 422
    return erb :new_file
  end

  unless has_valid_file_extension?(filename)
    session[:error] = "The file must end with a file extension of either .txt or .md"
    status 422
    return erb :new_file
  end

  file_path = File.join(settings.data_path, filename)
  File.write(file_path, "")
  session[:success] = "#{filename} was created."
  redirect "/"
end

post "/data/:file/delete" do
  filename = params[:file].strip
  file_path = File.join(settings.data_path, filename)

  if File.exist?(file_path)
    File.delete(file_path)
    session[:success] = "#{filename} was deleted."
    redirect "/"
  else
    session[:error] = "The file doesn't exist."
  end
end