# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  def new
    if sso_enabled?
      redirect_to user_doorkeeper_omniauth_authorize_url
    else
      super
    end
  end

  def destroy
    current_user.update(authentication_token: nil) # generate new token
    sign_out(current_user)

    if sso_enabled?
      redirect_to "#{@organization.auth_app_url}#{app_secrets.routes[:auth_app][:logout_path]}"
    else
      redirect_to new_user_session_path
    end
  end
end
