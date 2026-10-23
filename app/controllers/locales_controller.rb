# The language switch in the navbar. Open to visitors who are not signed in;
# for a signed-in user the choice is also saved on the account, so it follows
# them to other devices and picks the language of their emails.
class LocalesController < ApplicationController
  def update
    locale = params[:locale].to_s
    locale = I18n.default_locale.to_s unless I18n.available_locales.map(&:to_s).include?(locale)

    cookies.permanent[:locale] = locale
    current_user&.update_column(:locale, locale)
    redirect_back_or_to root_path, status: :see_other
  end
end
