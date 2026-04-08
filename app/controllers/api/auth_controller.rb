class Api::AuthController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  # POST /api/auth/register
  def register
    user_params = params.require(:user).permit(:username, :email, :password, :password_confirmation)
    
    @user = User.new(user_params)
    
    if @user.save
      session[:user_id] = @user.id
      render json: { 
        user: { 
          id: @user.id, 
          username: @user.username, 
          email: @user.email 
        },
        auth_token: SecureRandom.hex(16)
      }
    else
      render json: { error: @user.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # POST /api/auth/login
  def login
    # Support both email and username login
    login_param = params[:email] || params[:username]
    
    user = User.find_by(email: login_param) || User.find_by(username: login_param)
    
    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
      render json: { 
        user: { 
          id: user.id, 
          username: user.username, 
          email: user.email 
        },
        auth_token: SecureRandom.hex(16)
      }
    else
      render json: { error: "Invalid email/username or password" }, status: :unauthorized
    end
  end

  # DELETE /api/auth/logout
  def destroy
    session.delete(:user_id)
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
    render json: { message: "Logged out successfully" }
  end

  # GET /api/auth/me
  def me
    if logged_in?
      render json: { 
        user: { 
          id: current_user.id, 
          username: current_user.username, 
          email: current_user.email 
        }
      }
    else
      render json: { error: "Not authenticated" }, status: :unauthorized
    end
  end
end
