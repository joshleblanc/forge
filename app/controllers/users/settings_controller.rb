class Users::SettingsController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
    @api_keys = @user.api_keys.order(created_at: :desc)
  end

  def update
    @user = current_user

    if user_params[:username].present? && @user.username != user_params[:username]
      if User.exists?(username: user_params[:username])
        flash.now[:alert] = "Username is already taken"
        render :show, status: :unprocessable_entity
        return
      end
      @user.username = user_params[:username]
    end

    if user_params[:email].present? && @user.email != user_params[:email]
      if User.exists?(email: user_params[:email])
        flash.now[:alert] = "Email is already in use"
        render :show, status: :unprocessable_entity
        return
      end
      @user.email = user_params[:email]
    end

    if @user.save
      flash[:notice] = "Profile updated successfully"
      redirect_to settings_path
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      render :show, status: :unprocessable_entity
    end
  end

  def claim_key
    key_string = params[:key_string]&.strip
    if key_string.blank?
      flash[:alert] = "Please enter an API key"
      redirect_to settings_path
      return
    end

    api_key = ApiKey.find_by_key(key_string)
    if api_key.nil?
      flash[:alert] = "Invalid API key"
      redirect_to settings_path
      return
    end

    if api_key.user == current_user
      flash[:notice] = "This key is already linked to your account"
      redirect_to settings_path
      return
    end

    if api_key.user && !api_key.user.anonymous?
      flash[:alert] = "This key is already linked to another account"
      redirect_to settings_path
      return
    end

    # Claim the key - transfer from anonymous to this user
    api_key.update!(user: current_user, anonymous: false)
    flash[:notice] = "API key '#{api_key.display_name}' has been claimed!"
    redirect_to settings_path
  rescue => e
    flash[:alert] = "Could not claim key: #{e.message}"
    redirect_to settings_path
  end

  def create_key
    name = params[:name]&.strip.presence || "New Key #{current_user.api_keys.count + 1}"

    key = ApiKey.create!(
      user: current_user,
      name: name,
      anonymous: false
    )

    flash[:notice] = "API key created: #{key.display_name}"
    redirect_to settings_path
  end

  def destroy_key
    key = current_user.api_keys.find(params[:id])
    key.destroy!
    flash[:notice] = "API key deleted"
    redirect_to settings_path
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Key not found"
    redirect_to settings_path
  end

  def regenerate_key
    key = current_user.api_keys.find(params[:id])
    key.regenerate_key!
    flash[:notice] = "API key regenerated for #{key.display_name}"
    redirect_to settings_path
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Key not found"
    redirect_to settings_path
  end

  private

  def user_params
    params.require(:user).permit(:username, :email)
  end
end
