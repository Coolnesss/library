class UsersController < ApplicationController

  before_action :authorize_self, except: [:inactive]
  before_action :authorize_admin, only: [:inactive, :confirm, :index, :destroy]

  def inactive
    @users = User.where(active: nil).order(created_at: :desc)
  end

  def index
    @users = User.all.order(:email)
  end

  def confirm
    user_params = params.permit(:confirm, :user_id, :authenticity_token)
    user = User.find(user_params[:user_id])
    user.active = true? user_params[:confirm]
    
    if user.active
      UserMailer.with(user: user).user_approved_email.deliver_later
      user.save
    else
      user.destroy
    end
    
    redirect_to inactive_path, notice: build_notice(user)
  end

  def edit
    @user = current_user
    @user = User.find(params[:id]) if params[:id]  
  end

  def update
    @user = current_user
    @user = User.find(params[:id]) if params[:id]

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

  def destroy
    @user = User.find(params[:id]) if params[:id]
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def build_notice(user)
    if user.destroyed?
      "User was rejected successfully." 
    else
      "User was activated successfully."
    end
  end

  def true?(obj)
    obj.to_s == "true"
  end
end
