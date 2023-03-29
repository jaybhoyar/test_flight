# frozen_string_literal: true

module Desk::Mailboxes::EmailConfigurations
  class CreateService < BaseService
    attr_reader :email_configuration_params
    attr_accessor :email_configuration

    def initialize(organization, email_configuration_params)
      super(organization)
      @email_configuration_params = email_configuration_params
    end

    def process
      initialize_email_configuration
      assign_forward_to_email

      @email_configuration.save!
      @email_configuration
    end

    private

      def initialize_email_configuration
        @email_configuration = @organization.email_configurations.new(email_configuration_params)
      end
  end
end
