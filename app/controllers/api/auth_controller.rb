class Api::AuthController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_by_api_key, only: [:verify]

  # POST /api/auth/verify
  # Validates an API key and returns identity info.
  # Used by the Forge base library to check publish permissions.
  def verify
    if @api_key
      render json: {
        valid: true,
        user_id: @api_key.user&.id,
        username: @api_key.user&.username,
        anonymous: @api_key.anonymous?,
        can_publish: @api_key.can_publish?,
        display_name: @api_key.display_name
      }
    else
      render json: { valid: false, error: "Invalid API key" }, status: :unauthorized
    end
  end

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
  # Works with either session cookie or API key in Authorization header.
  def me
    user = resolve_user

    if user
      render json: {
        user: {
          id: user.id,
          username: user.username,
          email: user.email
        },
        anonymous: user.anonymous?,
        api_keys: user.api_keys.map { |k| {
          id: k.id,
          name: k.name,
          display_name: k.display_name,
          download_count: k.download_count,
          publish_count: k.publish_count,
          created_at: k.created_at
        }}
      }
    elsif @api_key
      # Authenticated by API key but no user — anonymous
      render json: {
        user: nil,
        anonymous: true,
        can_publish: false,
        api_key: {
          id: @api_key.id,
          name: @api_key.name,
          display_name: @api_key.display_name,
          download_count: @api_key.download_count,
          publish_count: @api_key.publish_count
        }
      }
    else
      render json: { error: "Not authenticated" }, status: :unauthorized
    end
  end
end
