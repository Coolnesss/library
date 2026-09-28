require 'test_helper'

class PublicPagesTest < ActionDispatch::IntegrationTest
  test "the home page shows the thought of the day" do
    get root_path
    assert_response :success
    assert_includes response.body, '<strong>thought</strong>'
  end

  test "the about, login and register pages are open to everyone" do
    [about_path, login_path, register_path].each do |path|
      get path
      assert_response :success, "expected #{path} to be public"
    end
  end

  test "the health check answers without a login" do
    get '/up'
    assert_response :success
  end
end
