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
  end

  def teardown
    FileUtils.rm_f Dir[File.join(@data_path, "*")]
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_viewing_text_document
    get "data/about.txt"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Ruby"
  end

  def test_index_if_user_views_nonexistent_file
    nonexistent_file = "data/#{Time.now.to_i}_#{SecureRandom.hex(2)}.txt"
    get "data/#{nonexistent_file}"
    assert_equal 302, last_response.status
  end
end