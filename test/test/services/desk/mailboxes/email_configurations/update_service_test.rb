# frozen_string_literal: true

require "test_helper"

class Desk::Mailboxes::EmailConfigurations::UpdateServiceTest < ActiveSupport::TestCase
  def setup
    @email_configuration = create(:email_configuration)
  end

  def test_updates_email_configuration_success
    update_email_configuration_service = update_service(@email_configuration, email_configuration_params)

    assert update_email_configuration_service.process
    assert update_email_configuration_service.email_configuration.valid?

    @email_configuration.reload
    assert "support@example.com", @email_configuration.email
  end

  def test_fails_to_update_with_invalid_params
    invalid_email_configuration_params = email_configuration_params("")
    update_email_configuration_service = update_service(@email_configuration, invalid_email_configuration_params)

    assert_not update_email_configuration_service.process
  end

  private

    def email_configuration_params(email = "support")
      {
        email:
      }
    end

    def update_service(email_configuration, params)
      Desk::Mailboxes::EmailConfigurations::UpdateService.new(email_configuration, params)
    end
end
