# frozen_string_literal: true

class Auth::OrganizationsController < ApplicationController
  def edit
    redirect_to "#{@organization.auth_app_url}#{app_secrets.routes[:auth_app][:edit_organization]}"
  end
end
