# frozen_string_literal: true

class Auth::ChangeEmailsController < ApplicationController
  def new
    if sso_enabled?
      redirect_to "#{@organization.auth_app_url}#{app_secrets.routes[:auth_app][:change_email_path]}"
    else
      redirect_to app_secrets.routes[:app][:change_email_path]
    end
  end
end
