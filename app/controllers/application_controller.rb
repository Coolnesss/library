class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user
  
  def current_user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def authorize
    redirect_to login_path, notice: 'You should be signed in' if not current_user
  end

  def authorize_admin
    redirect_to login_path, notice: 'You should be an admin to do that' if current_user and not current_user.admin?
  end

  def authorize_self
    redirect_to login_path, notice: "This isn't yours to modify!" if params[:id] and User.find(params[:id]) != current_user
  end
end
