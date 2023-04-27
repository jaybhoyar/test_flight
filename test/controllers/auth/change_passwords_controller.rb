# frozen_string_literal: true

class Auth::ChangePasswordsController < ApplicationController
  def new
    if sso_enabled?
      redirect_to "#{@organization.auth_app_url}#{app_secrets.routes[:auth_app][:change_password_path]}"
    else
      redirect_to app_secrets.routes[:app][:change_password_path]
    end
  end
end
