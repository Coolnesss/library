require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test "the approval email goes to the user" do
    mail = UserMailer.with(user: users(:pending)).user_approved_email

    assert_equal ['pending@example.com'], mail.to
    assert_equal 'Your Antilibrary account was approved', mail.subject
  end
end
