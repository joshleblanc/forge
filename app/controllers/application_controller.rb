class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :logged_in?, :current_user

  private

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
