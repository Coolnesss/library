class UserMailer < ApplicationMailer
  def user_approved_email
      @user = params[:user]

      mail(to: @user.email, subject: "Your Antilibrary account was approved")
  end
end
