require 'yaml'
require 'sinatra'
require "sinatra/reloader"
require 'erb'

before do
  @users = YAML.load_file(File.join(settings.root, "users.yaml")).transform_keys(&:to_sym)
end

get "/" do
  erb :home
end

get "/user/:name" do
  puts @users
  @user_key = params[:name].to_sym
  @user_name = params[:name]
  @user_email = @users[@user_key][:email]
  @user_interests = @users[@user_key][:interests]
  @other_users = @users.keys - [@user_key]

  erb :user
end

helpers do
  def num_users
    @users.keys.count
  end

  def num_interests
    counter = 0
    @users.each do |name, details|
      counter += details[:interests].size
    end
    counter
  end
end
