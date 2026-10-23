class ApplicationController < ActionController::Base
  # Lets file URLs from the local disk service (development) include the host.
  include ActiveStorage::SetCurrent

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user, :rtl?, :english_only?

  around_action :switch_locale

  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def rtl?
    I18n.locale == :sd
  end

  # Admin pages are not translated. The layout keeps them left to right, so
  # their English tables do not come out mirrored on Sindhi pages.
  def english_only?
    false
  end

  def authorize
    redirect_to login_path, notice: t('sessions.sign_in_first') if not current_user
  end

  def authorize_admin
    redirect_to login_path, notice: 'You should be an admin to do that' if (not current_user) or (current_user and not current_user.admin?)
  end

  # Guards pages about one user. Registering has no :id, so it stays open to
  # visitors who are not signed in; asking current_user for its admin flag
  # there used to raise.
  def authorize_self
    return unless params[:id]

    user = User.find_by(id: params[:id])
    return if current_user and (user == current_user or current_user.admin?)

    redirect_to login_path, notice: "This isn't yours to modify!"
  end

  private

  # The signed-in user's choice, else this browser's, else Sindhi.
  def switch_locale(&action)
    locale = [current_user&.locale, cookies[:locale]].find { |choice| I18n.available_locales.map(&:to_s).include?(choice.to_s) }
    I18n.with_locale(locale || I18n.default_locale, &action)
  end
end
