class UserMailerPreview < ActionMailer::Preview
    def user_approved_email
        # Set up a temporary user for the preview
        user = User.new(name: "Joe Smith", email: "joe@gmail.com")
    
        UserMailer.with(user: user).user_approved_email
      end
end
