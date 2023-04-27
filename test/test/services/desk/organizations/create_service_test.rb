# frozen_string_literal: true

require "test_helper"

class Desk::Organizations::CreateServiceTest < ActiveSupport::TestCase
  def test_create_organization_with_default_data
    Sidekiq::Testing.inline!

    organization = nil
    service = ::Desk::Organizations::CreateService.new(payload)
    assert_difference "Organization.count", 1 do
      organization = service.process
    end

    assert organization.setting.present?
    assert_equal 1, organization.customer_satisfaction_surveys.count
    assert_equal 1, organization.business_hours.count
    assert_equal 5, organization.business_hours.first.schedules.count
    assert_equal 1, organization.business_hours.first.holidays.count
    assert_equal 2, organization.roles.count
    assert_equal 1, organization.agents.count
    assert_equal 6, organization.tickets.count

    # Mailbox
    assert_equal 1, organization.email_configurations.count
    assert_equal "support", organization.email_configurations.first.email
    assert_equal \
      "support.#{organization.subdomain}@#{Rails.application.secrets.mailbox[:domain]}",
      organization.email_configurations.first.forward_to_email
  end

  private

    def payload
      {
        name: Faker::Company.name,
        api_key: "spinkart",
        subdomain: "spinkart"
      }
    end
end
