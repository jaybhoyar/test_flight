# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  def new
    if sso_enabled?
      redirect_to "#{app_secrets.auth_app[:url]}#{app_secrets.routes[:auth_app][:signup_path]}"
    else
      super
    end
  end
end
