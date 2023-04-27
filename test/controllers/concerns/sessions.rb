# frozen_string_literal: true

module Sessions
  extend ActiveSupport::Concern

  included do
    include Devise::Controllers::Rememberable

    def perform_sign_in(params)
      return false if @resource.blank?
      return false unless @resource.active_for_authentication?

      if @resource.valid_password?(params[:password])
        params[:remember_me] ? remember_me(@resource) : forget_me(@resource)
        sign_in "user", @resource

        true
      else
        false
      end
    end

    def error_message
      if @resource.blank?
        "Incorrect email or password"
      elsif !@resource.active?
        t("devise.failure.deactivated")
      else
        t("devise.failure.#{@resource.unauthenticated_message}")
      end
    end
  end
end
