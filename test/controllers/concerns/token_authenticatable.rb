# frozen_string_literal: true

module TokenAuthenticatable
  extend ActiveSupport::Concern

  attr_reader :user

  def authenticate_user_using_x_auth_token
    email = request.headers["X-Auth-Email"]
    auth_token = request.headers["X-Auth-Token"]

    @user = email &&
      @organization &&
      User.find_first_by_auth_conditions(email:, organization_id: @organization.id)

    if valid_user_token?(auth_token)
      sign_in user, store: false
    else
      message = if user && !user.active?
        t("devise.failure.deactivated")
      else
        t("devise.failure.timeout")
      end

      respond_with_error(message, 401)
    end
  end

  private

    def valid_user_token?(auth_token)
      user &&
        user.active? &&
        user.correct_authentication_token?(auth_token) &&
        user.token_valid?
    end
end
