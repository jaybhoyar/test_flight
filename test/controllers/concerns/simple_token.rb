# frozen_string_literal: true

module SimpleToken
  extend ActiveSupport::Concern

  included do
    def verify_user_token
      token = params[:user_token]
      return false unless token

      hex_timestamp = token.split(".", 2)[0]
      generated_token = OpenSSL::HMAC.hexdigest(
        "SHA256", Rails.application.secrets.devise[:secret_key],
        "#{hex_timestamp}.#{params[:email]}")
      if ActiveSupport::SecurityUtils.secure_compare("#{hex_timestamp}.#{generated_token}", token)
        hex_timestamp.to_i(16) > (Time.now.to_i - 3.hours.to_i)
      end
    end
  end
end
