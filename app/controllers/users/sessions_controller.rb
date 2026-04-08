class Users::SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :destroy]
  
  def new
    if logged_in?
      redirect_to root_path
    end
  end

  def create
    user = User.find_by(email: params[:email].downcase) || User.find_by(username: params[:email])
    
    if user && user.authenticate(params[:password])
      if params[:remember_me] == '1'
        cookies.permanent[:user_id] = user.id
        cookies.permanent[:remember_token] = user.remember_token
      else
        cookies[:user_id] = user.id
        cookies[:remember_token] = user.remember_token
      end
      session[:user_id] = user.id
      
      redirect_to root_path, notice: "Welcome back, #{user.username}!"
    else
      flash.now[:alert] = "Invalid email/username or password"
      render :new, status: :unauthorized
    end
  end

  def destroy
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
    session.delete(:user_id)
    redirect_to root_path, notice: "Logged out successfully"
  end
end
