# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def doorkeeper
    @auth = request.env["omniauth.auth"]
    from_omniauth_service = Desk::Users::FromOmniauthService.new(@auth)
    from_omniauth_service.process

    if @auth.info.role == "owner" || auth_user_has_access?
      if from_omniauth_service.success?
        user = from_omniauth_service.user
        sign_in_and_redirect user, event: :authentication
      else
        session["devise.doorkeeper_data"] = request.env["omniauth.auth"]
        flash[:error] = from_omniauth_service.response[:error]
        redirect_to root_url
      end
    else
      redirect_to_auth_app_error_url
    end
  end

  def failure
    redirect_to root_path
  end

  def auth_user_has_access?
    (client_app_present? && @auth.info.deactivated_at.nil?) || @auth.info.neeto_apps.length == 0
  end

  def redirect_to_auth_app_error_url
    auth_uri = URI(app_secrets.auth_app[:url].gsub(app_secrets.app_subdomain, @organization.subdomain))
    auth_uri.path = "/error"
    auth_uri.query = URI.encode_www_form({ access: :denied })

    redirect_to(auth_uri.to_s)
  end

  def app_secrets
    @_app_secrets ||= Rails.application.secrets
  end

  def client_app_present?
    @auth.info.neeto_apps.find { |neeto_app| neeto_app.app_name == app_secrets.client_app_name }.present?
  end
end
