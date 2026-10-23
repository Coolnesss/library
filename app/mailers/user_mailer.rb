class UserMailer < ApplicationMailer
  def user_approved_email
      @user = params[:user]

      # Accounts from before the language switch have no locale. They
      # registered on the English site.
      I18n.with_locale(@user.locale.presence || :en) do
        mail(to: @user.email)
      end
  end
end
