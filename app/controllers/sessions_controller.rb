class SessionsController < ApplicationController

  def new
  end

  def create
    user = User.find_by_email(params[:email].downcase)
    # If the user exists AND the password entered is correct.
    if user && user.authenticate(params[:password]) && user.active?
      # Save the user id inside the browser cookie. This is how we keep the user
      # logged in when they navigate around our website.
      session[:user_id] = user.id
      redirect_to '/'
    elsif user && user.authenticate(params[:password])
      redirect_to login_path, notice: t('sessions.not_approved')
    else
      # Used to say nothing, which looked like the page had just reloaded.
      redirect_to login_path, alert: t('sessions.wrong_password')
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to '/login'
  end

end
