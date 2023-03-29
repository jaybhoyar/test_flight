# frozen_string_literal: true

module Desk::Mailboxes::EmailConfigurations
  class UpdateService < BaseService
    attr_reader :email_configuration, :email_configuration_params

    def initialize(email_configuration, email_configuration_params)
      super(email_configuration.organization)
      @email_configuration = email_configuration
      @email_configuration_params = email_configuration_params
    end

    def process
      initialize_email_configuration_attributes
      assign_forward_to_email

      email_configuration.save
    end

    private

      def initialize_email_configuration_attributes
        email_configuration.assign_attributes(email_configuration_params)
      end
  end
end
