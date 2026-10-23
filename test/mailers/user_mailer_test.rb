require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test "the approval email goes to the user" do
    mail = UserMailer.with(user: users(:pending)).user_approved_email

    assert_equal ['pending@example.com'], mail.to
    assert_equal 'Your Antilibrary account was approved', mail.subject
  end

  test "the approval email is in the user's language" do
    user = users(:pending)
    user.update!(locale: 'sd')
    mail = UserMailer.with(user: user).user_approved_email

    assert_equal 'توهان جو ائنٽي لائبريري کاتو منظور ٿي ويو', mail.subject
    assert_includes mail.text_part.body.to_s, 'سلام Pending۔'
    assert_includes mail.html_part.body.to_s, 'dir="rtl"'
  end
end
