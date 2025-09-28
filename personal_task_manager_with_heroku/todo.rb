require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubi"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

helpers do
  def list_complete?(list)
    incomplete_todos = list[:todos].any? {|hash| hash[:completed] == false}
    list[:todos].size > 0 && incomplete_todos == false
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_count(list)
    list[:todos].size
  end

  def todos_completed_count(list)
    completed_todos = list[:todos].select {|todo| todo[:completed] == true}
    completed_todos.size
  end

  def todos_remaining_count(list)
    remaining_todos = list[:todos].select {|todo| todo[:completed] == false}
    remaining_todos.size
  end

  def sort_lists_with_index(lists, &block)
    lists.each_with_index.sort_by { |(list, _i)| list_complete?(list) ? 1 : 0 }
  end

  def sort_todos_with_index(todos)
    todos.each_with_index.sort_by { |(todo, _i)| todo[:completed] ? 1 : 0 }
  end
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists_with_idx = sort_lists_with_index(session[:lists])
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# Return an error message if the name is invalid
# Returns nil if name is valid
def error_for_list_name(name)
  if !(1..100).cover? name.size
  "List name must be between 1 and 100 characters."
  elsif session[:lists].any? {|list| list[:name] == name}
    "List name must be unique."
  end
end

# Return an error message if the todo is invalid
# Returns nil if name is valid
def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo must be between 1 and 100 characters."
  end
end

# Load a list and return an error if user attempts to access an invalid list
def load_list(index)
  list = session[:lists][index] if index && session[:lists][index]
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# View an individual list with todo items
get "/lists/:id" do
  @id = params[:id].to_i
  @list = load_list(@id)
  erb :list, layout: :layout
end

# Render the edit list form
get "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = load_list(@id)
  erb :edit_list, layout: :layout
end

# Edit an individual list (change the name of the list)
post "/lists/:id/edit_list" do
  @id = params[:id].to_i
  @list = load_list(@id)

  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists"
  end
end

# Delete an individual list
post "/lists/:id/destroy" do
  id = params[:id].to_i

  session[:lists].delete_at(id)
  session[:success] = "The list was deleted."
  redirect "/lists"
end

# Add an new todo item to a list
post "/lists/:list_id/todos" do
  @id = params[:list_id].to_i
  @list = load_list(@id)
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << {name: text, completed: false}
    session[:success] = "The todo was added."
    redirect "/lists/#{@id}"
  end
end

# Delete a todo item from a list
post "/lists/:list_id/delete_todo/:todo_number" do
  @id = params[:list_id].to_i
  @list = load_list(@id)
  idx = params[:todo_number].to_i

  @list[:todos].delete_at(idx)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo was deleted."
    redirect "/lists/#{@id}"
  end
end

# Mark a todo item as completed or incomplete
post "/lists/:list_id/todos/:todo_number" do
  @id = params[:list_id].to_i
  @list = load_list(@id)
  idx = params[:todo_number].to_i

  specific_todo_item = @list[:todos][idx]
  is_completed = params[:completed] == "true"
  specific_todo_item[:completed] = is_completed

  session[:success] = "The todo has been updated."
  redirect "/lists/#{@id}"
end

# Mark all items in a todo list as completed
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  @list[:todos].each_with_index do |todo_item, idx|
    todo_item[:completed] = true
  end
  
  session[:success] = "Each todo has been marked as completed."
  redirect "/lists/#{@list_id}"
end