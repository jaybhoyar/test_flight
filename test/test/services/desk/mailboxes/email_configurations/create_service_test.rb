# frozen_string_literal: true

require "test_helper"

class Desk::Mailboxes::EmailConfigurations::CreateServiceTest < ActiveSupport::TestCase
  def setup
    @organization = create(:organization)
  end

  def test_creates_new_email_configuration
    assert_difference "EmailConfiguration.count", 1 do
      email_configurations_create_service.process
    end
  end

  def test_fails_to_create_new_email_configuration
    invalid_email_configuration_params = {
      email: ""
    }

    assert_raises ActiveRecord::RecordInvalid do
      Desk::Mailboxes::EmailConfigurations::CreateService.new(@organization, invalid_email_configuration_params).process
    end
  end

  def test_forward_to_email_format_in_non_production_env
    email_configuration = email_configurations_create_service.process
    assert email_configuration.forward_to_email.match(/\A([\w+\-]\.?)+@[a-z\d\-]+(\.[a-z]+)*\.net/)
  end

  def test_forward_to_email_format_in_production_env
    email_configuration = email_configurations_create_service.process
    assert email_configuration.forward_to_email.start_with? "support."
  end

  private

    def email_configurations_create_service
      Desk::Mailboxes::EmailConfigurations::CreateService.new(@organization, create_email_configuration_params)
    end

    def create_email_configuration_params(email = "support")
      {
        email:
      }
    end
end
