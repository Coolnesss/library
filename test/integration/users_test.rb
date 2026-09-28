require 'test_helper'

class UsersTest < ActionDispatch::IntegrationTest
  test "registering creates an account that waits for approval" do
    get register_path
    assert_response :success

    assert_difference 'User.count', 1 do
      post users_path, params: { user: { name: ' New Reader ', email: 'new@example.com', password: 'secret1', password_confirmation: 'secret1' } }
    end
    assert_redirected_to login_path

    user = User.find_by(email: 'new@example.com')
    assert_equal 'New Reader', user.name
    assert_nil user.active
  end

  test "registering with errors shows the form again" do
    assert_no_difference 'User.count' do
      post users_path, params: { user: { name: '', email: 'not-an-email', password: 'secret1', password_confirmation: 'secret1' } }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, 'Please provide a name'
  end

  test "an admin approves a user, which emails them" do
    sign_in users(:admin)
    get inactive_path
    assert_includes response.body, users(:pending).email

    assert_enqueued_emails 1 do
      post confirm_path, params: { user_id: users(:pending).id, confirm: true }
    end
    assert_redirected_to inactive_path
    assert users(:pending).reload.active
  end

  test "an admin rejecting a user deletes them" do
    sign_in users(:admin)

    assert_difference 'User.count', -1 do
      post confirm_path, params: { user_id: users(:pending).id, confirm: false }
    end
    assert_redirected_to inactive_path
  end

  test "only admins manage users" do
    sign_in users(:reader)

    get inactive_path
    assert_redirected_to login_path
    get users_path
    assert_redirected_to login_path
    assert_no_difference 'User.count' do
      delete user_path(users(:pending))
    end
    assert_redirected_to login_path
  end

  test "an admin lists and deletes users" do
    sign_in users(:admin)

    get users_path
    assert_response :success
    assert_includes response.body, users(:reader).email

    assert_difference 'User.count', -1 do
      delete user_path(users(:reader))
    end
    assert_redirected_to users_url
  end

  test "a user changes their own password" do
    sign_in users(:reader)
    get change_password_path
    assert_response :success

    patch user_path(users(:reader)), params: { user: { password: 'changed1', password_confirmation: 'changed1' } }
    assert_redirected_to root_path

    get logout_path
    sign_in users(:reader), password: 'changed1'
    assert_redirected_to root_path
  end

  test "a signed-out visitor is sent to the login page, not an error" do
    get edit_user_path(users(:admin))
    assert_redirected_to login_path
  end

  test "a user cannot edit someone else" do
    sign_in users(:reader)

    get edit_user_path(users(:admin))
    assert_redirected_to login_path

    patch user_path(users(:admin)), params: { user: { password: 'hijack1', password_confirmation: 'hijack1' } }
    assert_redirected_to login_path
    assert users(:admin).reload.authenticate(PASSWORD)
  end
end
