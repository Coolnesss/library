class UsersController < ApplicationController

  before_filter :authorize_self

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to root_path, notice: 'Password changed successfully.' }
        format.json { render :show, status: :ok }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def register
    @user = User.new
  end

  def create
    @user = User.new user_params

    if @user.save
      redirect_to login_path, notice: 'User created succesfully. Wait for an admin to activate your account.'
    else
      render :register
    end
  end

    # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

end
