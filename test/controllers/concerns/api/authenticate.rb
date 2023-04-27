# frozen_string_literal: true

module Api::Authenticate
  extend ActiveSupport::Concern

  include TokenAuthenticatable

  included do
    before_action :authenticate_user_using_x_auth_token
    before_action :authenticate_user_for_api
  end

  private

    def authenticate_user_for_api
      unless user_signed_in?
        respond_with_error(t("authentication.unauthorized"), :unauthorized) and return
      end
    end

    def authenticate_organization_api_key!
      unless @organization.api_key == request.headers["X-Neeto-API-Key"]
        respond_with_error(t("authentication.unauthorized"), :unauthorized) and return
      end
    end
end
