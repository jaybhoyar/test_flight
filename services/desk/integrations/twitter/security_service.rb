# frozen_string_literal: true

module Desk::Integrations::Twitter
  class SecurityService
    attr_accessor :details

    def initialize(details = {})
      @details = details
    end

    def generate_crc_response
      hash = OpenSSL::HMAC.digest("sha256", api_secret, details[:crc_token])
      response_token = "sha256=" + Base64.encode64(hash).strip!

      { response_token: }
    end

    private

      def api_secret
        Rails.application.secrets.twitter[:api_secret]
      end
  end
end
