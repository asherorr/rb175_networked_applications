# book_viewer.rb
require "sinatra"

configure :development do
  require "sinatra/reloader"  # comes from sinatra-contrib
  also_reload "./**/*.rb" if respond_to?(:also_reload)
end

get "/" do
  "Hello from Sinatra!"
end
