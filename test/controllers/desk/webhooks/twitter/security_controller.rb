# frozen_string_literal: true

module Desk
  module Webhooks::Twitter
    class SecurityController < ApplicationController
      respond_to :json
      skip_before_action :verify_authenticity_token, :load_organization

      # Twitter Challenge-Response Checks
      # Ref: https://developer.twitter.com/en/docs/accounts-and-users/subscribe-account-activity/guides/securing-webhooks
      def crc_check
        details = crc_check_params.to_h
        response = ::Desk::Integrations::Twitter::SecurityService.new(details).generate_crc_response
        render json: response, status: :ok
      end

      private

        def crc_check_params
          params.permit(:crc_token, :format, :nonce)
        end
    end
  end
end
