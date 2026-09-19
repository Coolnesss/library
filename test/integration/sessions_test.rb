require 'test_helper'

class SessionsTest < ActionDispatch::IntegrationTest
  test "an active user can log in and out" do
    sign_in users(:reader)
    assert_redirected_to root_path

    get books_path
    assert_response :success

    get logout_path
    get books_path
    assert_redirected_to login_path
  end

  test "the email is matched case-insensitively" do
    post login_path, params: { email: 'Reader@Example.com', password: PASSWORD }
    assert_redirected_to root_path
  end

  test "a user waiting for approval cannot log in" do
    sign_in users(:pending)
    assert_redirected_to login_path
    assert_equal "Your account hasn't been activated by an admin yet", flash[:notice]

    get books_path
    assert_redirected_to login_path
  end

  test "a wrong password is refused" do
    sign_in users(:reader), password: 'wrong'
    assert_redirected_to login_path

    get books_path
    assert_redirected_to login_path
  end
end
