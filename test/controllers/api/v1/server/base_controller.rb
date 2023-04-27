# frozen_string_literal: true

class Api::V1::Server::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :load_organization

  before_action :verify_http_authenticity_token

  private

    def verify_http_authenticity_token
      authorization_token = app_secrets.server_authorization_token

      authenticate_or_request_with_http_token do |token, options|
        ActiveSupport::SecurityUtils.secure_compare(token, authorization_token)
      end
    end

    def set_organization
      @organization = Organization.find_by(subdomain: params[:subdomain])
      unless @organization
        render json: {
          success: false,
          error: t("resource.not_found", resource_name: "Organization")
        }, status: :not_found and return
      end
    end
end
