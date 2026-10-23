require 'test_helper'

class SessionsTest < ActionDispatch::IntegrationTest
  test "an active user can log in and out" do
    sign_in users(:reader)
    assert_redirected_to root_path

    get books_path
    assert_response :success

    delete logout_path
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
    assert_equal I18n.t('sessions.not_approved', locale: :sd), flash[:notice]

    get books_path
    assert_redirected_to login_path
  end

  test "a wrong password is refused" do
    sign_in users(:reader), password: 'wrong'
    assert_redirected_to login_path

    get books_path
    assert_redirected_to login_path
  end

  test "signing out takes a DELETE, so a prefetched link cannot sign anyone out" do
    sign_in users(:reader)
    get '/logout'
    assert_response :not_found
    get books_path
    assert_response :success
    assert_select 'form[action=?] input[name=_method][value=delete]', logout_path
  end
end
