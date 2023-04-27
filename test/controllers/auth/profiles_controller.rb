# frozen_string_literal: true

class Auth::ProfilesController < ApplicationController
  def edit
    if sso_enabled?
      redirect_to "#{@organization.auth_app_url}#{app_secrets.routes[:auth_app][:edit_profile_path]}"
    else
      redirect_to app_secrets.routes[:app][:edit_profile_path]
    end
  end
end
