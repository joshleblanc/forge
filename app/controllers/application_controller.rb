class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :logged_in?, :current_user, :api_key

  private

  # Authenticate via API key from Authorization: Bearer <key> header
  # Used by the Forge base library for in-game package management
  def authenticate_by_api_key
    token = request.headers["Authorization"]&.sub(/^Bearer\s+/i, "")
    return nil if token.blank?

    @api_key = ApiKey.find_by_key(token)
    @api_key
  end

  # Resolve the authenticated user — either from session or API key
  def resolve_user
    return current_user if logged_in?
    return api_key&.user if api_key
    nil
  end

  # Is the resolved user logged in (has a registered account)?
  def user_logged_in?
    return true if logged_in?
    return false if api_key&.anonymous?
    api_key&.user.present?
  end

  # Can the resolved identity publish? (requires registered user, not anonymous)
  def can_publish?
    return false if api_key&.anonymous?
    api_key&.can_publish? || logged_in?
  end

  # Require publish permission — used before publishing actions
  def require_publish_permission
    return if can_publish?

    message = if api_key&.anonymous?
      "Anonymous API keys cannot publish. Register at https://forge.game to enable publishing."
    else
      "Authentication required to publish packages."
    end

    render json: { error: message }, status: :forbidden
  end

  def logged_in?
    return true if session[:user_id]
    return true if cookies[:user_id] && cookies[:remember_token]
    
    if cookies[:user_id] && cookies[:remember_token]
      user = User.find_by(id: cookies[:user_id])
      if user && user.remember_token == cookies[:remember_token]
        session[:user_id] = user.id
        return true
      end
    end
    false
  end

  def current_user
    return @current_user if defined?(@current_user)
    
    if session[:user_id]
      @current_user = User.find_by(id: session[:user_id])
    elsif cookies[:user_id] && cookies[:remember_token]
      user = User.find_by(id: cookies[:user_id])
      if user && user.remember_token == cookies[:remember_token]
        session[:user_id] = user.id
        @current_user = user
      else
        @current_user = nil
      end
    else
      @current_user = nil
    end
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "Please log in to continue"
    end
  end
end
