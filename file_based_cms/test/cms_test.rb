ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    @data_path = app.settings.data_path
    FileUtils.mkdir_p(@data_path)
    File.write(File.join(@data_path, "about.txt"),   "Ruby is...")
    File.write(File.join(@data_path, "changes.txt"), "Recent Ruby changes")
    File.write(File.join(@data_path, "history.txt"), "History of Ruby")
    File.write(File.join(@data_path, "about.md"), "# Introduction to Ruby")
    File.write(File.join(@data_path, "file_to_delete.md"), "# This file will be deleted.")
  end

  def teardown
    FileUtils.rm_f Dir[File.join(@data_path, "*")]
  end

  def session
    last_request.env["rack.session"]
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_viewing_text_document
    get "/data/about.txt"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Ruby"
  end

  def test_index_if_user_views_nonexistent_file
    nonexistent_file = "/data/#{Time.now.to_i}_#{SecureRandom.hex(2)}.txt"
    get "/data/#{nonexistent_file}"
    assert_equal 404, last_response.status
  end

  def test_markdown_file_converts_to_html
    get "/data/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    assert_includes last_response.body, "<h1>Introduction to Ruby</h1>"
  end

  def test_editing_document
    get "/data/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, '<button type="submit"' 
  end

  def test_updating_document
    post "/data/changes.txt/edit_file", content: "new content"

    assert_equal 302, last_response.status
    assert_equal "/", URI(last_response["Location"]).path
    assert_equal "changes.txt has been updated.", session[:success]

    # Test that the file actually changed
    path = File.join(@data_path, "changes.txt")
    assert_includes File.read(path), "new content"
  end

  def test_new_document_creation
    post "/new_file", file_name: "newfile.txt"

    assert_equal 302, last_response.status
    assert_equal "/", URI(last_response["Location"]).path
    assert_equal "newfile.txt was created.", session[:success]
  end

  def test_deleting_document
    # Test that file exists
    file_name = "file_to_delete.md"
    file_path = File.join(@data_path, file_name)
    assert File.exist?(file_path)

    # Test that file is deleted
    post "/data/#{file_name}/delete"
    refute File.exist?(file_path)

    # Test redirection to index page upon deletion
    assert_equal 302, last_response.status
    assert_equal "/", URI(last_response["Location"]).path
    assert_equal "#{file_name} was deleted.", session[:success]

    # Test that index page no longer displays the deleted file
    get "/"
    refute_includes last_response.body, %Q{href="/data/#{file_name}"}
  end

  def test_sign_in_form
    get "/sign_in"
    assert_includes last_response.body, '<button type="submit">Sign In</button>'
  end

  def test_sign_in_with_bad_credentials
    post "/sign_in", username: "not_admin", password: "not_secret"

    assert_equal 302, last_response.status
    assert_equal "/sign_in", URI(last_response["Location"]).path
    assert_equal "Invalid credentials", session[:error]
  end


  def test_sign_in_with_correct_credentials
    post "/sign_in", username: "admin", password:"secret"

    assert_equal 302, last_response.status
    assert_equal "admin", session[:username]
    assert_equal "Welcome!", session[:success] 
  end

  def test_sign_out_form
    post "/sign_out"
    assert_equal "", session[:username]
    assert_equal 302, last_response.status
    assert_equal 'You have been signed out.', session[:success]
  end
end