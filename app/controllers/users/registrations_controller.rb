class Users::RegistrationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  
  def new
    if logged_in?
      redirect_to root_path
    end
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    if @user.valid?
      @user.save
      session[:user_id] = @user.id
      cookies[:user_id] = @user.id
      redirect_to root_path, notice: "Welcome, #{@user.username}! Your account has been created."
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end
end
