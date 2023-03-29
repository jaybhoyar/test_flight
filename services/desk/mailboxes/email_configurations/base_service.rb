# frozen_string_literal: true

class Desk::Mailboxes::EmailConfigurations::BaseService
  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  private

    def assign_forward_to_email
      email_configuration.forward_to_email = email_configuration_params[:email]
    end
end
